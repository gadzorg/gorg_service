#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class Consumer
    module MessageHandler
      class RequestHandler < Base

        def reply_with(data)
          if message.expect_reply?

            reply=GorgService::Message.new(
              event: message.reply_routing_key,
              data: data,
              correlation_id: message.id,
              type: "reply"
            )

            replier=GorgService::Producer.new
            replier.publish_message(reply,exchange: message.reply_to)
          end
        end

        def raise_hardfail(message, error: nil, data: nil)
          reply_with({
                         status: 'hardfail',
                         error_message: message,
                         debug_message: error&&error.inspect,
                         error_data: data
                     })

          super(message, error: nil)
        end

        def raise_softfail(message, error: nil, data: nil)
          reply_with({
                         status: 'softfail',
                         error_message: message,
                         debug_message: error&&error.inspect,
                         error_data: data
                     })
          super(message, error: nil)
        end

      end
    end
  end
end