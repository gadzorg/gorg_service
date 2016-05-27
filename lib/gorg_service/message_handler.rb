#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class MessageHandler

    def initialize(message)
      puts "WARNING : Defined your MessageHandler behavior in its 'initialize' method"
    end

    def raise_hardfail(message, error:nil)
      raise HardfailError.new(error), message
    end

    def raise_softfail(message, error:nil)
      raise SoftfailError.new(error), message
    end

  end
end