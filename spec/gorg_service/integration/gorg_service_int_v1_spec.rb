require 'spec_helper'
require 'securerandom'
require 'gorg_service/rspec/bunny_cleaner'


class SimpleMessageHandler < GorgService::Consumer::MessageHandler::Base


  
  def initialize(msg)
    GorgService.logger.debug "Message received in SimpleMessageHandler"
    @@message=msg
  end

  def self.message
    @@message||=""
  end

  def self.reset
    @@message=nil
  end
end

class LogMessageHandler < GorgService::Consumer::MessageHandler::Base

  listen_to "log.routing.key"
  
  def initialize(msg)
    GorgService.logger.debug "Message received in LogMessageHandler"
    @@message=msg
  end

  def self.message
    @@message||=""
  end

  def self.reset
    @@message=nil
  end
end

class SoftfailMessageHandler < GorgService::Consumer::MessageHandler::Base
  def initialize(msg)
    GorgService.logger.debug "Message received in SoftfailMessageHandler"
    @@message=msg
    self.class.add_attempt
    puts "attempts = #{self.class.attempts}"
    raise_softfail(msg.routing_key.to_s)
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

class HardfailMessageHandler < GorgService::Consumer::MessageHandler::Base
  def initialize(msg)
    GorgService.logger.debug "Message received in HardfailMessageHandler"
    raise_hardfail(msg.routing_key.to_s)
  end
end

class ExceptionMessageHandler < GorgService::Consumer::MessageHandler::Base
  def initialize(msg)
    GorgService.logger.debug "Message received in ExceptionMessageHandler"
    raise "Some Error"
  end
end



describe "Integrations tests SOAv1" do

  before(:all) do

    @test_session_uuid="testing_exchange_#{SecureRandom.uuid}"
    puts "Using UUID : #{ @test_session_uuid}"
  end

  around(:each) do |example|
    BunnyCleaner.cleaning do
      example.run
    end
  end

  before(:each) do
    SoftfailMessageHandler.reset
    SimpleMessageHandler.reset
    LogMessageHandler.reset

    GorgService::Consumer::MessageRouter.routes.delete_if{|x|true}

    @exchange_name="testing_exchange_#{@test_session_uuid}"
    @app_id="gdd-testing-#{@test_session_uuid}"
  end


  describe 'no wildcard routing key' do
    before(:each) do

      LogMessageHandler.listen_to "log.routing.key"
      handler.listen_to "testing_key"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.rabbitmq_client_class=BunnyCleaner
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id=@app_id
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_event_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
        c.log_routing_key="log.routing.key"
      end
        

      @service=GorgService::Consumer.new
      @service.start
      @conn=@service.instance_variable_get(:@bunny_session)
    end

    after(:each) do
      @service.stop

      sleep(3)

      # chan=@conn.channel
      # chan.topic(@exchange_name, durable:true).delete
      # chan.topic("#{@app_id}.reply", durable:true).delete
      # chan.topic("#{@app_id}.request", durable:true).delete
      # chan.queue("#{@app_id}_job_q", durable: true).delete
      #
      # chan.close



    end

    let(:message) {GorgService::Message.new(routing_key: "testing_key", data:{test_data: "testing_message"})}


    describe "simple message handler" do

      let(:handler) {SimpleMessageHandler}

      it "Send message to MessageHandler" do
        GorgService::Producer.new().publish_message(message)
        sleep(2)
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}


      before(:each) do

        GorgService::Producer.new().publish_message(message)
        sleep(3)
      end

      it "retry 3 times" do
        expect(handler.message.data).to eq({test_data: "testing_message"})
        expect(handler.attempts).to eq(3)
      end

      it "send error to logging key" do
        expect(LogMessageHandler.message).to have_attributes(
                                                 correlation_id: message.id,
                                                 type: 'log',
                                                 error_type: 'hardfail',
                                             )
      end



    end

    describe "hardfail" do
      let(:handler) {HardfailMessageHandler}

      it "send error to logging key" do
        GorgService::Producer.new().publish_message(message)

        sleep(3)

        expect(LogMessageHandler.message).to have_attributes(
                                                 correlation_id: message.id,
                                                 type: 'log',
                                                 error_type: 'hardfail',
                                             )
      end

    end

    describe "Unhandled Excceptions" do
      let(:handler) {ExceptionMessageHandler}

      it "raise a HardFail Error" do
        GorgService::Producer.new().publish_message(message)

        sleep(2)

        expect(LogMessageHandler.message).to have_attributes(
                                                 correlation_id: message.id,
                                                 type: 'log',
                                                 error_type: 'hardfail',
                                             )
      end

    end
  end

  describe 'with wildcard routing key' do
    before(:each) do

      LogMessageHandler.listen_to "log.routing.key"
      handler.listen_to "*.testing_key.#"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.rabbitmq_client_class=BunnyCleaner
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id=@app_id
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_event_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
      end

      @service=GorgService::Consumer.new
      @service.start
    end

    after(:each) do
      @service.stop
    end

    describe "simple message handler" do

      let(:handler) {SimpleMessageHandler}

      it "Send message to MessageHandler" do
        GorgService::Producer.new().publish_message(GorgService::Message.new(routing_key: "my.testing_key.is.awesome", data:{test_data: "testing_message"}))
        sleep(3)
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}

      it "retry 3 times" do
        GorgService::Producer.new().publish_message(GorgService::Message.new(routing_key: "my.testing_key", data:{test_data: "testing_message"}))

        sleep(5)

        expect(handler.message.data).to eq({test_data: "testing_message"})
        expect(handler.attempts).to eq(3)
      end
    end
  end
end