require "bunny"
require "json"
require 'securerandom'

class MessageSender
  def initialize(r_host: "localhost", r_port: "5672", r_user:nil, r_pass:nil, r_exchange:nil, r_vhost: "/")
    @r_host=r_host
    @r_port=r_port
    @r_user=r_user
    @r_pass=r_pass
    @r_exchange=r_exchange
    @r_vhost=r_vhost
  end

  def message(data,routing_key)
    {
      "event_uuid" => SecureRandom.uuid,
      "event_name" => routing_key,
      "event_creation_time" => DateTime.now.iso8601,
      "event_sender_id" => "tester",
      "data"=> data,
    }.to_json
  end

  def send(data,routing_key,opts={})
    self.start
    p_opts={}
    p_opts[:routing_key]= routing_key if routing_key

    @x.publish(message(data,routing_key), p_opts)
    self.stop
  end

  def start
    @conn||=Bunny.new(
      :hostname => @r_host,
      :port => @r_port,
      :user => @r_user,
      :pass => @r_pass,
      :vhost => @r_vhost
      )
    @conn.start
    ch = @conn.create_channel
    @x  = ch.topic(@r_exchange, :durable => true)
  end

  def stop
    @conn.close
  end

end