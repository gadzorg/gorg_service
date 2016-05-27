require "gorg/rabbitmq_bot/configuration"
require "gorg/rabbitmq_bot/version"
require "gorg/rabbitmq_bot/errors"
require "gorg/rabbitmq_bot/listener"
require "gorg/rabbitmq_bot/message"
require "gorg/rabbitmq_bot/message_handler"

module Gorg
  class RabbitmqBot
    def initialize()
      @listener=Listener.new(
        message_handler_map:Gorg::RabbitmqBot.configuration.message_handler_map,
        host: Gorg::RabbitmqBot.configuration.rabbitmq_host,
        port: Gorg::RabbitmqBot.configuration.rabbitmq_port,
        queue_name: Gorg::RabbitmqBot.configuration.rabbitmq_queue_name,
        exchange_name: Gorg::RabbitmqBot.configuration.rabbitmq_exchange_name,
        rabbitmq_user: Gorg::RabbitmqBot.configuration.rabbitmq_user,
        rabbitmq_password: Gorg::RabbitmqBot.configuration.rabbitmq_password,
        deferred_time: Gorg::RabbitmqBot.configuration.rabbitmq_deferred_time,
        )
    end

    def run
      @listener.listen
    end
  end
end
