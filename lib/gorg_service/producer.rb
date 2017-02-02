#!/usr/bin/env ruby
# encoding: utf-8


class GorgService
  class Producer

    attr_accessor :default_exchange
    attr_accessor :environment

    def initialize(environment_: GorgService.environment ,default_exchange_: nil)
      self.environment=environment_
      self.default_exchange= default_exchange_ || environment.event_exchange
    end


    def publish_message(message, exchange: default_exchange)
      x=exchange.is_a?(Bunny::Exchange) ? exchange : environment.find_exchange_by_name(exchange)
      GorgService.logger.info "Publish to #{x.name} - key : #{message.event}"
      GorgService.logger.debug "Message content : #{message.body}"

      x.publish(message.to_json, message.properties)
    end

  end
end