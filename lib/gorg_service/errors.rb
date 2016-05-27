#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class FailError < StandardError
    attr_reader :error_raised

    def initialize(error_raised)
      @error_raised = error_raised
    end
  end

  class SoftfailError < FailError
  end

  class HardfailError < FailError
  end
end