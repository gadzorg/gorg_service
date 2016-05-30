#!/usr/bin/env ruby
# encoding: utf-8

class GorgService

  #Common behavior of failling errors
  class FailError < StandardError
    attr_reader :error_raised

    def initialize(message = nil, error_raised = nil)
      @message = message
      @error_raised = error_raised
    end

    def message
      @message
    end

    def type
      ""
    end
  end

  #Softfail error : This message should be processed again later
  class SoftfailError < FailError
    def type
      "softfail"
    end
  end

  #Hardfail error : This message is not processable and will never be
  class HardfailError < FailError
    def type
      "hardfail"
    end
  end
end