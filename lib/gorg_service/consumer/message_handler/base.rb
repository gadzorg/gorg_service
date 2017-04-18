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

        def reply_with(*_args, **keyword_args)
          self.class.reply_to(message,**keyword_args)
        end

        def raise_hardfail(*args, **keyword_args)
          self.class.raise_hardfail(*args, **(keyword_args.merge(message:message)))
        end

        def raise_softfail(*args, **keyword_args)
          self.class.raise_softfail(*args, **(keyword_args.merge(message:message)))
        end

        class << self

          def reply_to(message, data: {}, status_code: 200, error_type: nil, error_name: nil, next_try_in: nil)
            if message.expect_reply?

              reply=message.reply_message(
                  data: data,
                  status_code: status_code,
                  error_type: error_type,
                  error_name: error_name,
                  next_try_in: next_try_in,
              )

              replier=GorgService::Producer.new
              replier.publish_message(reply,exchange: message.reply_to)
            end
          end

          def raise_hardfail(error_message,message:nil, error: nil, data: nil, status_code: 500, error_name: nil)
            if message
              reply_to(message,{
                  error_type: 'hardfail',
                  status_code: status_code,
                  error_name: error_name,
                  data:{
                    error_message: error_message,
                    debug_message: error&&error.inspect,
                    error_data: data
                  },

              })
            end
            raise HardfailError.new(error_message, error, gorg_service_message: message, error_name: error_name)
          end

          def raise_softfail(error_message,message:nil, error: nil, data: nil, status_code: 500, error_name: nil)
            if message
              reply_to(message,{
                  error_type: 'softfail',
                  next_try_in: GorgService.configuration.rabbitmq_deferred_time.to_i,
                  status_code: status_code,
                  error_name: error_name,
                  data:{
                      error_message: error_message,
                      debug_message: error&&error.inspect,
                      error_data: data
                  },
              })
            end
            raise SoftfailError.new(error_message, error, gorg_service_message: message, error_name: error_name)
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