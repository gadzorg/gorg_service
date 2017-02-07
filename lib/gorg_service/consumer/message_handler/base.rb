#!/usr/bin/env ruby
# encoding: utf-8
class GorgService
  class Consumer
    module MessageHandler
      class Base

        def initialize(message)
          @message=message

          begin
            validate
          rescue GorgService::Message::DataValidationError => e
            raise_hardfail("DataValidationError",error: e.errors)
          end
          process
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
          raise HardfailError.new(message, error)
        end

        def raise_softfail(message, error: nil)
          raise SoftfailError.new(message, error)
        end

        class << self

          def listen_to(routing_key)
            MessageRouter.register_route(routing_key, self)
          end

        end
      end
    end
  end
end