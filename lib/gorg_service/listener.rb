#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

class GorgService
  class Listener

    def initialize(bunny_session: nil,queue_name: "gapps", exchange_name: nil, message_handler_map: {default: DefaultMessageHandler}, deferred_time: 1800000, max_attempts: 48,log_routing_key:nil)
      @queue_name=queue_name
      @exchange_name=exchange_name
      @message_handler_map=message_handler_map
      @deferred_time=deferred_time
      @max_attempts=max_attempts
      @rmq_connection=bunny_session
      @log_routing_key=log_routing_key
    end

    def listen

      set_rabbitmq_env
   
      @q.subscribe(:manual_ack => true) do |delivery_info, _properties, body|
        routing_key=delivery_info[:routing_key]
        puts " [#] Received message with routing key #{routing_key} containing : #{body}"
        process_message(body,routing_key)
        @ch.ack(delivery_info.delivery_tag)
      end
    end

    protected

    def rmq_connection
      @rmq_connection.start unless @rmq_connection.connected?
      @rmq_connection
    end

    def set_rabbitmq_env
      conn = rmq_connection
      @ch   = conn.create_channel
      @ch.prefetch(1)
      @ch.topic(@exchange_name, :durable => true)
      @q    = @ch.queue(@queue_name, :durable => true)

      @message_handler_map.keys.each do |routing_key|
        @q.bind(@exchange_name, :routing_key => routing_key)
      end
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
        puts " [*] SOFTFAIL ERROR : #{e.message}"
        if message.errors.count >= @max_attempts
          puts " [*] DISCARD MESSAGE : #{message.errors.count} errors in message log"
          process_hardfail(HardfailError.new("Too Much SoftError : This message reached the limit of softerror (max: #{@max_attempts})"),message)
        else
          send_to_deferred_queue(message)
        end
    end

    def process_hardfail(e,message)
      puts " [*] HARDFAIL ERROR : #{e.message}"
      puts " [*] DISCARD MESSAGE"
      if message
        message.log_error(e)
        process_logging(message)
      end
    end

    def process_logging(message)
      RabbitmqProducer.new.send_raw(message.to_json,@log_routing_key, verbose: true) if @log_routing_key
    end

    def send_to_deferred_queue(msg)
      conn=rmq_connection
      @delayed_chan||=conn.create_channel
      q=@delayed_chan.queue("#{@queue_name}_deferred",
        durable: true,
        arguments: {
            'x-message-ttl' => @deferred_time,
            'x-dead-letter-exchange' => @exchange_name,
            'x-dead-letter-routing-key' => msg.event,
          }
        )
      puts " [*] DEFER MESSAGE : message sent to #{@queue_name}_deferred qith routing key #{msg.event}"
      q.publish(msg.to_json, :routing_key => msg.event)
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