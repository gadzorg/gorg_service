#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class Consumer
    class MessageRouter

      def initialize(message)
        message_handler=self.class.message_handler_for message.routing_key
        raise HardfailError.new("Routing error : No message handler finded for this routing key") unless message_handler

        message_handler.new(message)
      end

      class << self

        def routes
          @routes||={}
        end

        def register_route(routing_key, message_handler)
          routes[routing_key]=message_handler
        end

        def listened_keys
          routes.keys
        end

        def message_handler_for routing_key
          @routes.each do |k, mh|
            return mh if amqp_key_to_regex(k).match(routing_key)
          end
        end

        private

        def amqp_key_to_regex(key)
          regex_base=key.gsub('.', '\.')
                         .gsub('*', '([a-zA-Z0-9\-_:]+)')
                         .gsub(/(\\\.)?#(\\\.)?/, '((\.)?[a-zA-Z0-9\-_:]*(\.)?)*')

          /^#{regex_base}$/
        end

      end
    end
  end
end