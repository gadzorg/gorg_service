class GorgService
  class RabbitmqEnvBuilder

    def initialize(conn:nil, event_exchange:"", app_id:"", deferred_time: 10000, listened_routing_keys: [], prefetch: 1)
      @_conn=conn
      @app_id=app_id
      @event_exchange_name=event_exchange
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
      unless (@_ch && @_ch.status == :open)
        @_ch=conn.create_channel
        @_ch.prefetch(1)
      end
      @_ch
    end

    def request_exchange
      ch.topic("#{@app_id}.request", :durable => true)
    end

    def reply_exchange
      ch.topic("#{@app_id}.reply", :durable => true)
    end

    def event_exchange
      ch.topic(@event_exchange_name, :durable => true)
    end


    def delayed_in_exchange
     ch.topic("#{@app_id}_delayed_in_x", :durable => true)
    end

    def delayed_out_exchange
      ch.fanout("#{@app_id}_delayed_out_x", :durable => true)
    end

    def job_queue
      GorgService.logger.debug "Listened keys :#{@listened_routing_keys}"
      q=ch.queue("#{@app_id}_job_q", :durable => true)
      q.bind delayed_out_exchange
      @listened_routing_keys.each do |rk|
        q.bind(event_exchange, :routing_key => rk)
      end
      q.bind(reply_exchange, :routing_key => "#")
      q.bind(request_exchange, :routing_key => "#")
      q
    end

    def delayed_queue_for routing_key
      @delayed_queues[routing_key]||= create_delayed_queue_for(routing_key)
    end

    private

    def set_logger
      x=ch.fanout("log", :durable => true)
      x.bind(event_exchange, :routing_key => "#")
      x.bind(reply_exchange, :routing_key => "#")
      x.bind(request_exchange, :routing_key => "#")
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