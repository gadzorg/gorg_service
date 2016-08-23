#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

class GorgService
  class Listener

    def initialize(bunny_session: nil, env: nil, message_handler_map: {default: DefaultMessageHandler}, max_attempts: 48,log_routing_key:nil)
      @message_handler_map=message_handler_map
      @max_attempts=max_attempts
      @rmq_connection=bunny_session
      @log_routing_key=log_routing_key

      @env=env
    end

    def listen  
      @env.job_queue.subscribe(:manual_ack => true) do |delivery_info, _properties, body|
        routing_key=delivery_info[:routing_key]
        GorgService.logger.info "Received message with routing key #{routing_key} containing : #{body}"
        process_message(body,routing_key)
        @env.ch.ack(delivery_info.delivery_tag)
      end
    end

    protected

    def rmq_connection
      @rmq_connection.start unless @rmq_connection.connected?
      @rmq_connection
    end

    def process_message(body,routing_key)
      message=nil
      incomming_message_error_count=0
      begin 
        message_handler=message_handler_for routing_key
        raise HardfailError.new("Routing error : No message handler finded for this routing key") unless message_handler

        begin
          message=Message.parse_body(body)
        rescue JSON::ParserError => e
          raise HardfailError.new("JSON Parse error : Can't parse incoming message",e)
        rescue JSON::Schema::ValidationError => e
          raise HardfailError.new("Invalid JSON : This message does not respect Gadz.org JSON Schema",e)
        end
        incomming_message_error_count=message.errors.count
        message_handler.new(message)
        process_logging(message) if message.errors.count>incomming_message_error_count
      rescue SoftfailError => e
        process_softfail(e,message)
      rescue HardfailError => e
        process_hardfail(e,message)
      end
    end

    def process_softfail(e,message)
        message.log_error(e)
        GorgService.logger.error "SOFTFAIL ERROR : #{e.message}"
        if message.errors.count >= @max_attempts
          GorgService.logger.info " DISCARD MESSAGE : #{message.errors.count} errors in message log"
          process_hardfail(HardfailError.new("Too Much SoftError : This message reached the limit of softerror (max: #{@max_attempts})"),message)
        else
          send_to_deferred_queue(message)
        end
    end

    def process_hardfail(e,message)
      GorgService.logger.error "HARDFAIL ERROR : #{e.message}"
      GorgService.logger.info " DISCARD MESSAGE"
      if message
        message.log_error(e)
        process_logging(message)
      end
    end

    def process_logging(message)
      RabbitmqProducer.new.send_raw(message.to_json,@log_routing_key, verbose: true) if @log_routing_key
    end

    def send_to_deferred_queue(msg)
      if @env.delayed_queue_for msg.event
        @env.delayed_in_exchange.publish(msg.to_json, :routing_key => msg.event)
        GorgService.logger.info "DEFER MESSAGE : message sent to #{@env.delayed_in_exchange.name} with routing key #{msg.event}"
      else
        raise "DelayedQueueNotFound"
      end
    end

    def message_handler_for routing_key
      @message_handler_map.each do |k,mh|
        return mh if self.class.amqp_key_to_regex(k).match(routing_key)
      end
    end

    def self.amqp_key_to_regex(key)
      regex_base=key.gsub('.','\.')
                     .gsub('*','([a-zA-Z0-9\-_:]+)')
                     .gsub(/(\\\.)?#(\\\.)?/,'((\.)?[a-zA-Z0-9\-_:]*(\.)?)*')

      /^#{regex_base}$/
    end

  end
end