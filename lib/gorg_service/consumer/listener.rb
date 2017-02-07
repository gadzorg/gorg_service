#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

class GorgService
  class Consumer
    class Listener

      attr_accessor :consumer



      def initialize(env: nil, max_attempts: 48, log_routing_key: nil)
        @max_attempts=max_attempts.to_i
        @log_routing_key=log_routing_key

        @env=env
      end

      def listen
        @consumer=@env.job_queue.subscribe(:manual_ack => true) do |delivery_info, properties, body|
          #Log
          routing_key=delivery_info[:routing_key]
          GorgService.logger.info "Received message with routing key #{routing_key}"
          GorgService.logger.debug "Message properties : #{properties.to_s}"
          GorgService.logger.debug "Message payload : #{body.to_s[0...10000]}"

          #Process
          process_message(delivery_info, properties, body)

          #Acknoledge
          @env.ch.ack(delivery_info.delivery_tag)
        end
      end

      def stop
        @consumer.cancel
      end

      protected

      def process_message(delivery_info, _properties, body)
        message=nil
        begin
          #Parse message
          message=Message.parse(delivery_info, _properties, body)

          #Process message
          incomming_message_error_count=message.errors.count
          MessageRouter.new(message)
          process_logging(message) if message.errors.count>incomming_message_error_count

        rescue SoftfailError => e
          process_softfail(e, message)
        rescue HardfailError => e
          process_hardfail(e, message)
        end
      end

      def process_softfail(e, message)
        message.log_error(e)
        GorgService.logger.error "SOFTFAIL ERROR : #{e.message}"
        if message.errors.count.to_i >= @max_attempts
          GorgService.logger.info " DISCARD MESSAGE : #{message.errors.count} errors in message log"
          process_hardfail(HardfailError.new("Too Much SoftError : This message reached the limit of softerror (max: #{@max_attempts})"), message)
        else
          send_to_deferred_queue(message)
        end
      end

      def process_hardfail(e, message)
        GorgService.logger.error "HARDFAIL ERROR : #{e.message}, #{e.error_raised&&e.error_raised.inspect}"
        GorgService.logger.info " DISCARD MESSAGE"
        if message
          message.log_error(e)
          process_logging(message)
        end
      end

      def process_logging(message)
        message.routing_key=@log_routing_key
        GorgService::Producer.new.publish_message(message)
        #RabbitmqProducer.new.send_raw(message.to_json, @log_routing_key, verbose: true) if @log_routing_key
      end

      def send_to_deferred_queue(msg)
        if @env.delayed_queue_for msg.event
          @env.delayed_in_exchange.publish(msg.to_json, :routing_key => msg.event)
          GorgService.logger.info "DEFER MESSAGE : message sent to #{@env.delayed_in_exchange.name} with routing key #{msg.event}"
        else
          raise "DelayedQueueNotFound"
        end
      end
    end
  end
end