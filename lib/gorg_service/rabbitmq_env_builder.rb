class GorgService
  class RabbitmqEnvBuilder

    def initialize(conn:nil,main_exchange:"", app_id:"", deferred_time: 10000, listened_routing_keys: [])
      @_conn=conn
      @app_id=app_id
      @main_exchange_name=main_exchange
      @deferred_time=deferred_time
      @delayed_queues={}
      @listened_routing_keys=listened_routing_keys
      set_logger
    end

    def conn
      @_conn.start unless @_conn.connected?
      @_conn
    end

    def ch
      @_ch = (@_ch && @_ch.status == :open) ? @_ch : conn.create_channel
    end

    def main_exchange
      ch.topic(@main_exchange_name, :durable => true)
    end

    def delayed_in_exchange
     ch.topic("#{@app_id}_delayed_in_x", :durable => true)
    end

    def delayed_out_exchange
      ch.fanout("#{@app_id}_delayed_out_x", :durable => true)
    end

    def job_queue
      GorgService.logger.debug @listened_routing_keys
      q=ch.queue("#{@app_id}_job_q", :durable => true)
      q.bind delayed_out_exchange
      @listened_routing_keys.each do |rk|
        q.bind(main_exchange, :routing_key => rk)
      end
      q
    end

    def delayed_queue_for routing_key
      @delayed_queues[routing_key]||= create_delayed_queue_for(routing_key)
    end

    private

    def set_logger
      x=ch.fanout("log", :durable => true)
      x.bind(main_exchange, :routing_key => "#")
      x.bind(delayed_in_exchange, :routing_key => "#")
    end

    def create_delayed_queue_for(routing_key)
      q_name="#{@app_id}_#{routing_key.gsub(".","-")}_deferred_q"

      begin
        q=ch.queue(q_name,
          durable: true,
          arguments: {
              'x-message-ttl' => @deferred_time,
              'x-dead-letter-exchange' => delayed_out_exchange.name,
              'x-dead-letter-routing-key' => routing_key,
            }
          )

        q.bind(delayed_in_exchange.name, :routing_key => routing_key)
      rescue Bunny::PreconditionFailed => e
        if e.message.start_with?("PRECONDITION_FAILED - inequivalent arg")
          GorgService.logger.fatal("Mismatching configuration : admin action necessary. Error was : #{e.message}")
          raise "MismatchingConfig"
        end
        raise
      end
    end

  end
end

#ch.queue(test,  durable: true, arguments: {'x-message-ttl' => 1000,'x-dead-letter-exchange' => "agoram_event_exchange",'x-dead-letter-routing-key' => "test",})