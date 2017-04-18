#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class Consumer
    #Common behavior of failling errors
    class FailError < StandardError
      attr_reader :error_raised
      attr_reader :error_name
      attr_accessor :gorg_service_message

      def initialize(message = nil, error_raised = nil, gorg_service_message: nil, error_name: nil)
        @message = message
        @error_raised = error_raised
        @gorg_service_message = gorg_service_message
        @error_name = error_name
      end

      def message
        @message
      end

      def type
        ""
      end

      def to_log_message
        @gorg_service_message.log_message(
                                 level: self.log_level,
                                 error_type: self.type,
                                 error_name: @error_name
        )
      end
    end

    #Softfail error : This message should be processed again later
    class SoftfailError < FailError
      def type
        "softfail"
      end

      def log_level
        3
      end

      def to_log_message
        r=super
        r.next_try_in=GorgService.configuration.rabbitmq_deferred_time.to_i
        r
      end
    end

    #Hardfail error : This message is not processable and will never be
    class HardfailError < FailError
      def type
        "hardfail"
      end

      def log_level
        4
      end
    end
  end
end