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

        def raise_hardfail(message, error: nil)
          self.class.raise_hardfail(message, error: error)
        end

        def raise_softfail(message, error: nil)
          self.class.raise_softfail(message, error: error)
        end

        class << self
          def raise_hardfail(message, error: nil)
            raise HardfailError.new(message, error)
          end

          def raise_softfail(message, error: nil)
            raise SoftfailError.new(message, error)
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