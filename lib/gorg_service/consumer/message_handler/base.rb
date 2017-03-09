#!/usr/bin/env ruby
# encoding: utf-8
class GorgService
  class Consumer
    module MessageHandler
      class Base

        def initialize(message)
          @message=message

          GorgService::Consumer::MessageHandler::ExceptionManager.instance.with_exception_rescuing(self.message) do
            begin
              validate
            rescue GorgService::Message::DataValidationError => e
              raise_hardfail("DataValidationError",error: e.errors)
            end

            process
          end
        end

        def validate
          GorgService.logger.warn "WARNING : No message schema validation in #{self.class.name}, implement it in #validate(message) "
        end

        def process
          GorgService.logger.warn "WARNING : You must define your MessageHandler behavior in #process"
        end

        def message
          @message
        end
        alias_method :msg, :message

        def reply_with(data)
          self.class.reply_to(message, data)
        end

        def raise_hardfail(error_message, error: nil, data: nil)
          self.class.raise_hardfail(error_message, error: error, message:message, data:data)
        end

        def raise_softfail(error_message, error: nil, data: nil)
          self.class.raise_softfail(error_message, error: error, message:message, data:data)
        end

        class << self

          def reply_to(message,data)
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

          def raise_hardfail(error_message,message:nil, error: nil, data: nil)
            if message
              reply_to(message,{
                  status: 'hardfail',
                  error_message: error_message,
                  debug_message: error&&error.inspect,
                  error_data: data
              })
            end
            raise HardfailError.new(error_message, error)
          end

          def raise_softfail(error_message,message:nil, error: nil, data: nil)
            if message
              reply_to(message,{
                  status: 'softfail',
                  error_message: error_message,
                  debug_message: error&&error.inspect,
                  error_data: data
              })
            end
            raise SoftfailError.new(error_message, error)
          end

          def handle_error(*errorClasses,&block)
            GorgService::Consumer::MessageHandler::ExceptionManager.instance.set_rescue_from(*errorClasses,&block)
          end

          def listen_to(routing_key)
            MessageRouter.register_route(routing_key, self)
          end

          def reset_listen_to!
            MessageRouter.delete_routes_of(self)
          end

        end
      end
    end
  end
end