
require "gorg_service/configuration"
require "gorg_service/version"
require "gorg_service/rabbitmq_env_builder"
require "gorg_service/message"

require "gorg_service/consumer"
require "gorg_service/producer"

class GorgService
  class << self

    #Connection shared across Consumers and Producers (thread safe)
    def connection
      @bunny_session||=Bunny.new(
          :hostname => GorgService.configuration.rabbitmq_host,
          :port => GorgService.configuration.rabbitmq_port,
          :user => GorgService.configuration.rabbitmq_user,
          :pass => GorgService.configuration.rabbitmq_password,
          :vhost => GorgService.configuration.rabbitmq_vhost
      )
      @bunny_session.start unless @bunny_session.connected?
      @bunny_session
    end

    #Environment buidler. Don't share across threads since channels are not thread safe
    def environment
      RabbitmqEnvBuilder.new(
          conn: connection,
          event_exchange: GorgService.configuration.rabbitmq_event_exchange_name,
          app_id: GorgService.configuration.application_id,
          deferred_time: GorgService.configuration.rabbitmq_deferred_time.to_i,
          listened_routing_keys: Consumer::MessageRouter.listened_keys,
          prefetch: GorgService.configuration.prefetch_count,
      )
    end

    def logger
      GorgService.configuration.logger
    end

  end
end
