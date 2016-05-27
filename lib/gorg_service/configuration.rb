class GorgService
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end


    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :application_name,
                  :application_id,
                  :rabbitmq_host,
                  :rabbitmq_port,
                  :rabbitmq_queue_name,
                  :rabbitmq_exchange_name,
                  :rabbitmq_deferred_time,
                  :rabbitmq_max_attempts,
                  :rabbitmq_user,
                  :rabbitmq_password,
                  :message_handler_map,


    def initialize

      @application_name        = "GorgService"
      @application_id          = "gs" 
      @message_handler_map     = {}
      @rabbitmq_host           = "localhost"
      @rabbitmq_port           = 5672
      @rabbitmq_queue_name     = @application_id
      @rabbitmq_deferred_time  = 1800000    #30 minutes
      @rabbitmq_exchange_name  = "exchange"
      @rabbitmq_user           = nil
      @rabbitmq_password       = nil
      @rabbitmq_max_attempts   = 48         #24h with default timeout
    end
  end
end