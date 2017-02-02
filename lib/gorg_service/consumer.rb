#!/usr/bin/env ruby
# encoding: utf-8

require "gorg_service/consumer/message_router"
require "gorg_service/consumer/errors"
require "gorg_service/consumer/listener"
require "gorg_service/consumer/message_handler"

class GorgService
  class Consumer

    attr_accessor :environment

    def initialize(environment: GorgService.environment)
      @environment=environment
    end

    def listener
      @listener ||= Listener.new(
          env: environment,
          max_attempts: GorgService.configuration.rabbitmq_max_attempts.to_i,
          log_routing_key: GorgService.configuration.log_routing_key
      )
    end

    def run
      begin
        self.start
        puts " [*] Waiting for messages. To exit press CTRL+C"
        loop do
          sleep(1)
        end
      rescue SystemExit, Interrupt => _
        self.stop
      end
    end

    def start
      listener.listen
    end

    def stop
      listener.stop
    end
  end
end
