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
          begin
            #Parse message
            message=Message.parse(delivery_info, _properties, body)

            #Process message
            incomming_message_error_count=message.errors.count
            MessageRouter.new(message)
            process_logging(message) if message.errors.count>incomming_message_error_count
          rescue SoftfailError, HardfailError
            raise
          rescue  StandardError => e
            raise HardfailError.new("UnrescuedException", e)
          end
        rescue SoftfailError => e
          process_softfail(e, message)
        rescue HardfailError => e
          process_hardfail(e, message)
        end
      end

      def process_softfail(e, message)
        e.gorg_service_message ||= message
        GorgService.logger.error "SOFTFAIL ERROR : #{e.message}"
        process_logging(e)
        message.softfail_count+=1
        if message.softfail_count.to_i >= @max_attempts
          GorgService.logger.info " DISCARD MESSAGE : too much soft errors (#{message.softfail_count})"
          process_hardfail(HardfailError.new("Too Much SoftError : This message reached the limit of softerror (max: #{@max_attempts})", gorg_service_message: message, error_name: e.error_name), message)
        else
          send_to_deferred_queue(message)
        end
      end

      def process_hardfail(e, message)
        e.gorg_service_message ||= message
        GorgService.logger.error "HARDFAIL ERROR : #{e.message}, #{e.error_raised&&e.error_raised.inspect}"
        GorgService.logger.info " DISCARD MESSAGE"
        process_logging(e)
      end

      def process_logging(error)
        message=error.to_log_message
        message.routing_key=@log_routing_key
        GorgService::Producer.new.publish_message(message)
      end

      def send_to_deferred_queue(message)

        if @env.delayed_queue_for message.routing_key
          GorgService::Producer.new.publish_message(message, exchange: @env.delayed_in_exchange)
          #
          # @env.delayed_in_exchange.publish(msg.to_json, :routing_key => msg.routing_key)
          GorgService.logger.info "DEFER MESSAGE : message sent to #{@env.delayed_in_exchange.name} with routing key #{message.routing_key}"
        else
          raise "DelayedQueueNotFound"
        end
      end
    end
  end
end