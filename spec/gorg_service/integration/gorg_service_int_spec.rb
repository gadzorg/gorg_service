require 'spec_helper'
require 'bunny-mock'

class SimpleMessageHandler < GorgService::MessageHandler
  
  def initialize(msg)
    @@message=msg
  end

  def self.message
    @@message||=""
  end
end

class SoftfailMessageHandler < GorgService::MessageHandler
  def initialize(msg)
    @@message=msg
    self.class.add_attempt
    puts "attempts = self.attempts"
    raise_softfail(msg.event.to_s)
  end

  def self.attempts
    @@attempts||=0
  end

  def self.add_attempt
    @@attempts = self.attempts + 1
  end

  def self.message
    @@message
  end

end

class HardfailMessageHandler < GorgService::MessageHandler
  def initialize(msg)
    raise_hardfail(msg.event.to_s)
  end
end




$count = 0
describe "Integrations tests" do

  let!(:test_id) {$count += 1}

  before(:each) do
    GorgService.configuration=nil
    GorgService.configure do |c|
      c.application_name="GoogleDirectoryDaemon-test"
      c.application_id="gdd-testing"
      c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
      c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
      c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
      c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
      c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
      c.rabbitmq_queue_name="testing_queue_#{test_id}" #change queue to avoid collision between tests
      c.rabbitmq_exchange_name="testing_exchange"
      c.rabbitmq_deferred_time=100
      c.rabbitmq_max_attempts=3
      c.message_handler_map={"testing_key"=> handler}

      @service=GorgService.new
      @sender=MessageSender.new(
        r_host:RabbitmqConfig.value_at("r_host"),
        r_port:RabbitmqConfig.value_at("r_port"),
        r_user:RabbitmqConfig.value_at("r_user"),
        r_pass:RabbitmqConfig.value_at("r_pass"),
        r_vhost:RabbitmqConfig.value_at("r_vhost"),
        r_exchange: "testing_exchange"
        )
    end
  end

  describe "simple message handler" do

    let(:handler) {SimpleMessageHandler}

    it "Send message to MessageHandler" do
      puts "test_id : #{test_id}"
      @service.start
      @sender.send({test_data: "testing_message"},"testing_key")

      sleep(1)

      expect(handler.message.data).to eq({test_data: "testing_message"})

      @service.stop
    end
  end

  describe "softfail" do
    let(:handler) {SoftfailMessageHandler}

    it "retry 3 times" do
      puts "test_id : #{test_id}"
      @service.start
      @sender.send({test_data: "testing_message"},"testing_key")

      sleep(2)

      expect(handler.message.data).to eq({test_data: "testing_message"})
      expect(handler.attempts).to eq(3)

      @service.stop
    end
  end
end