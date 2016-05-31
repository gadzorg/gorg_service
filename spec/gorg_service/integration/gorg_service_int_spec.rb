require 'spec_helper'
require 'securerandom'
require 'gorg_message_sender'


class SimpleMessageHandler < GorgService::MessageHandler
  
  def initialize(msg)
    @@message=msg
  end

  def self.message
    @@message||=""
  end

  def self.reset
    @@message=nil
  end
end

class LogMessageHandler < GorgService::MessageHandler
  
  def initialize(msg)
    @@message=msg
  end

  def self.message
    @@message||=""
  end

  def self.reset
    @@message=nil
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

  def self.reset
    @@attempts=0
    @@message=nil
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

  before(:all) do

    @test_session_uuid="testing_exchange_#{SecureRandom.uuid}"
    puts "Using UUID : #{ @test_session_uuid}"

  end

  before(:each) do
    SoftfailMessageHandler.reset
    SimpleMessageHandler.reset
    LogMessageHandler.reset
  end

  describe 'no wildcard routing key' do
    before(:each) do

      @queue_name="testing_queue_#{@test_session_uuid}_#{test_id}"
      @exchange_name="testing_exchange_#{@test_session_uuid}"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id="gdd-testing"
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_queue_name=@queue_name #change queue to avoid collision between tests
        c.rabbitmq_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
        c.message_handler_map={"testing_key"=> handler,"log.routing.key"=>LogMessageHandler}
        c.log_routing_key="log.routing.key"
      end
        

      @service=GorgService.new
      @sender=GorgMessageSender.new(
        host:RabbitmqConfig.value_at("r_host"),
        port:RabbitmqConfig.value_at("r_port"),
        user:RabbitmqConfig.value_at("r_user"),
        pass:RabbitmqConfig.value_at("r_pass"),
        vhost:RabbitmqConfig.value_at("r_vhost"),
        exchange_name: @exchange_name
        )
      @service.start
    end

    after(:each) do
      @service.stop
    end


    describe "simple message handler" do

      let(:handler) {SimpleMessageHandler}

      it "Send message to MessageHandler" do
        puts "test_id : #{test_id}"
        @sender.send({test_data: "testing_message"},"testing_key")
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}

      before(:each) do
        puts "test_id : #{test_id}"
        @sender.send({test_data: "testing_message"},"testing_key")
        sleep(1)
      end

      it "retry 3 times" do
        expect(handler.message.data).to eq({test_data: "testing_message"})
        expect(handler.attempts).to eq(3)
      end

      it "send error to logging key" do
        expect(LogMessageHandler.message.data).to eq({test_data: "testing_message"})
      end


    end

    describe "hardfail" do
      let(:handler) {HardfailMessageHandler}

      it "send error to logging key" do
        puts "test_id : #{test_id}"

        @sender.send({test_data: "testing_message"},"testing_key")

        sleep(2)

        expect(LogMessageHandler.message.data).to eq({test_data: "testing_message"})
      end

    end
  end

  describe 'with wildcard routing key' do
    before(:each) do

      @queue_name="testing_queue_#{@test_session_uuid}_#{test_id}"
      @exchange_name="testing_exchange_#{@test_session_uuid}"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id="gdd-testing"
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_queue_name=@queue_name #change queue to avoid collision between tests
        c.rabbitmq_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
        c.message_handler_map={"*.testing_key.#"=> handler}
      end

      @service=GorgService.new
      @sender=GorgMessageSender.new(
        host:RabbitmqConfig.value_at("r_host"),
        port:RabbitmqConfig.value_at("r_port"),
        user:RabbitmqConfig.value_at("r_user"),
        pass:RabbitmqConfig.value_at("r_pass"),
        vhost:RabbitmqConfig.value_at("r_vhost"),
        exchange_name: @exchange_name
        )
      @service.start
    end

    after(:each) do
      @service.stop
    end

    describe "simple message handler" do

      let(:handler) {SimpleMessageHandler}

      it "Send message to MessageHandler" do
        puts "test_id : #{test_id}"
        @sender.send({test_data: "testing_message"},"my.testing_key.is.awesome")
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}

      it "retry 3 times" do
        puts "test_id : #{test_id}"
        @sender.send({test_data: "testing_message"},"my.testing_key")

        sleep(1)

        expect(handler.message.data).to eq({test_data: "testing_message"})
        expect(handler.attempts).to eq(3)
      end
    end
  end
end