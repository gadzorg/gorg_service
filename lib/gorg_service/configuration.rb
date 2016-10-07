# Add configuration features to GorgService
class GorgService
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end


    def configure
      @configuration = Configuration.new
      yield(configuration)
    end
  end

  # Hold configuration of GorgService in instance variables
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
                  :rabbitmq_vhost,
                  :message_handler_map,
                  :log_routing_key,
                  :logger,
                  :prefetch_count


    def initialize
      @logger                  = Logger.new(STDOUT)
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
      @rabbitmq_vhost          = "/"
      @rabbitmq_max_attempts   = 48         #24h with default timeout
      @log_routing_key         = nil
      @prefetch_count          = 1
    end
  end
end