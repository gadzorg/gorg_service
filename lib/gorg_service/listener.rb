#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

class GorgService
  class Listener

    def initialize(bunny_session: nil,queue_name: "gapps", exchange_name: nil, message_handler_map: {default: DefaultMessageHandler}, deferred_time: 1800000, max_attempts: 48)
      @queue_name=queue_name
      @exchange_name=exchange_name
      @message_handler_map=message_handler_map
      @deferred_time=deferred_time
      @max_attempts=max_attempts
      @rmq_connection=bunny_session
    end

    def listen

      conn = rmq_connection
      ch   = conn.create_channel
      x    = ch.topic(@exchange_name, :durable => true)
      q    = ch.queue(@queue_name, :durable => true)

      @message_handler_map.keys.each do |routing_key|
        q.bind(@exchange_name, :routing_key => routing_key)
      end

      q.bind(@exchange_name, :routing_key => '#')

      ch.prefetch(1)

      q.subscribe(:manual_ack => true) do |delivery_info, properties, body|
        routing_key=delivery_info[:routing_key]
        puts " [#] Received message with routing key #{routing_key} containing : #{body}"
        message_handler=message_handler_for routing_key
        message=Message.parse_body(body)

        call_message_handler(message_handler, message)

        ch.ack(delivery_info.delivery_tag)
      end

    end

    def rmq_connection
      @rmq_connection.start unless @rmq_connection.connected?
      @rmq_connection
    end

    def call_message_handler(message_handler, message)
      begin
        raise HardfailError.new(), "Routing error" unless message_handler
          message_handler.new(message)

      rescue SoftfailError => e
        message.log_error(e)
        process_softfail(e,message)

      rescue HardfailError => e
        message.log_error(e)
        process_hardfail(e)      
      end
    end

    def process_softfail(e,message)
        puts " [*] SOFTFAIL ERROR : #{e.message}"
        if message.errors.count >= @max_attempts
          puts " [*] DISCARD MESSAGE : #{message.errors.count} errors in message log"
        else
          send_to_deferred_queue(message)
        end
    end

    def process_hardfail(e)
      puts " [*] SOFTFAIL ERROR : #{e.message}"
      puts " [*] DISCARD MESSAGE"    
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