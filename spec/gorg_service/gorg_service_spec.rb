require 'spec_helper'

describe GorgService do
  fake(:listener) { GorgService::Listener }
  fake(:bunny_session) { Bunny::Session }
  fake(:env) { GorgService::RabbitmqEnvBuilder }

  it 'has a version number' do
    expect(GorgService::VERSION).not_to be nil
  end

  it "is configurable" do
    GorgService.configure do |c|
      c.application_name        = "my_name"
      c.application_id          = "app_id"
      c.rabbitmq_host           = "localhost"
      c.rabbitmq_port           = 1234
      c.rabbitmq_event_exchange_name  = "exchange"
      c.rabbitmq_deferred_time  = 1000
      c.rabbitmq_max_attempts   = 10
      c.rabbitmq_user           = "my_user"
      c.rabbitmq_password       = "P4ssWord"
      c.message_handler_map     = {"routting_key" => Class}
    end

    expect(GorgService.configuration.application_name).to        eq("my_name")
    expect(GorgService.configuration.application_id).to          eq("app_id")
    expect(GorgService.configuration.rabbitmq_host).to           eq("localhost")
    expect(GorgService.configuration.rabbitmq_port).to           eq(1234)
    expect(GorgService.configuration.rabbitmq_event_exchange_name).to  eq("exchange")
    expect(GorgService.configuration.rabbitmq_deferred_time).to  eq(1000)
    expect(GorgService.configuration.rabbitmq_max_attempts).to   eq(10)
    expect(GorgService.configuration.rabbitmq_user).to           eq("my_user")
    expect(GorgService.configuration.rabbitmq_password).to       eq("P4ssWord")
    expect(GorgService.configuration.message_handler_map).to     eq({"routting_key" => Class})
  end


end
