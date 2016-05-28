require "gorg_service/configuration"
require "gorg_service/version"
require "gorg_service/errors"
require "gorg_service/listener"
require "gorg_service/message"
require "gorg_service/message_handler"

class GorgService
  def initialize(listener: nil)

    @listener= listener || Listener.new(
      message_handler_map:GorgService.configuration.message_handler_map,
      host: GorgService.configuration.rabbitmq_host,
      port: GorgService.configuration.rabbitmq_port,
      queue_name: GorgService.configuration.rabbitmq_queue_name,
      exchange_name: GorgService.configuration.rabbitmq_exchange_name,
      rabbitmq_user: GorgService.configuration.rabbitmq_user,
      rabbitmq_password: GorgService.configuration.rabbitmq_password,
      deferred_time: GorgService.configuration.rabbitmq_deferred_time,
      max_attempts: GorgService.configuration.rabbitmq_max_attempts,
      )
  end

  def run
    @listener.listen
  end
end
