#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class Consumer
    module MessageHandler
      class ExceptionManager

        def self.instance
          @instance ||= self.new
        end

        def with_exception_rescuing(message=nil)
          begin
            begin
              yield
            rescue *rescuable_exceptions => e
              get_rescue_block_for(e).call(e,message)
            end
          rescue GorgService::Consumer::FailError => e
            raise e
          # rescue StandardError => e
          #   GorgService.logger.error "Uncaught exception : #{e.inspect}"
          #   raise HardfailError.new("UncaughtException", e)
          end
        end

        def set_rescue_from(*exception_classes,&block)
          exception_classes.each do |e|
            exceptions_hash[e]=block
          end
        end

        def rescuable_exceptions
          exceptions_hash.keys
        end

        def get_rescue_block_for(exception)
          exceptions_hash.find{|k,_v| exception.is_a?(k)}[1]
        end

        private

        def exceptions_hash
          @exceptions_hash ||= Hash.new
        end

      end
    end
  end
end