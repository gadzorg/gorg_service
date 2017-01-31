require 'spec_helper'
require 'securerandom'
require 'gorg_message_sender'


class SimpleMessageHandler < GorgService::MessageHandler


  
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

class LogMessageHandler < GorgService::MessageHandler

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

class SoftfailMessageHandler < GorgService::MessageHandler
  def initialize(msg)
    GorgService.logger.debug "Message received in SoftfailMessageHandler"
    @@message=msg
    self.class.add_attempt
    puts "attempts = #{self.class.attempts}"
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
    GorgService.logger.debug "Message received in HardfailMessageHandler"
    raise_hardfail(msg.event.to_s)
  end
end




$count = 0
describe "Integrations tests" do

  let!(:test_id) {$count += 1}

  before(:all) do

    @test_session_uuid="testing_exchange_#{SecureRandom.uuid}"
    puts "Using UUID : #{ @test_session_uuid}"

    @opened_topic_exchanges=[]
    @opened_fanout_exchanges=[]
    @opened_job_queues=[]
    @opened_deferred_queues=[]
  end

  after(:all) do
    conn=Bunny.new(
        :hostname => RabbitmqConfig.value_at("r_host"),
        :port => RabbitmqConfig.value_at("r_port"),
        :user => RabbitmqConfig.value_at("r_user"),
        :pass => RabbitmqConfig.value_at("r_pass"),
        :vhost => RabbitmqConfig.value_at("r_vhost"),
    )

    conn.start

    c=conn.create_channel


    @opened_topic_exchanges.each do |x|
      c.topic(x,durable:true).delete
    end
    @opened_fanout_exchanges.each do |x|
      c.fanout(x,durable:true).delete
    end
    @opened_job_queues.each do |q|
      c.queue(q,durable:true).delete
    end
    @opened_deferred_queues.each do |q|
      c.queue(q[:name],durable:true,arguments: q[:args]).delete
    end
  end

  before(:each) do
    SoftfailMessageHandler.reset
    SimpleMessageHandler.reset
    LogMessageHandler.reset

    GorgService::MessageRouter.routes.delete_if{|x|true}



    @exchange_name="testing_exchange_#{@test_session_uuid}"
    @app_id="gdd-testing-#{@test_session_uuid}_#{test_id}"
  end

  after(:each) do
    @opened_topic_exchanges<< @exchange_name
    @opened_topic_exchanges<< "#{@app_id}.reply"
    @opened_topic_exchanges<< "#{@app_id}.request"
    @opened_topic_exchanges<< "#{@app_id}_delayed_in_x"
    @opened_fanout_exchanges<< "#{@app_id}_delayed_out_x"
    @opened_job_queues<< "#{@app_id}_job_q"
    @opened_deferred_queues<< {name:"#{@app_id}_testing_key_deferred_q",
                               args: {
                                  'x-message-ttl' => 100,
                                  'x-dead-letter-exchange' => "#{@app_id}_delayed_out_x",
                                  'x-dead-letter-routing-key' => "testing_key",
                                  }
                              }
  end



  describe 'no wildcard routing key' do
    before(:each) do

      LogMessageHandler.listen_to "log.routing.key"
      handler.listen_to "testing_key"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id=@app_id
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_queue_name=@queue_name #change queue to avoid collision between tests
        c.rabbitmq_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
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



    describe "simple message handler" do

      let(:handler) {SimpleMessageHandler}

      it "Send message to MessageHandler" do
        puts "test_id : #{test_id}"
        @sender.send_message({test_data: "testing_message"},"testing_key")
        sleep(1)
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}

      before(:each) do
        puts "test_id : #{test_id}"
        @sender.send_message({test_data: "testing_message"},"testing_key")
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

        @sender.send_message({test_data: "testing_message"},"testing_key")

        sleep(2)

        expect(LogMessageHandler.message.data).to eq({test_data: "testing_message"})
      end

    end
  end

  describe 'with wildcard routing key' do
    before(:each) do

      LogMessageHandler.listen_to "log.routing.key"
      handler.listen_to "*.testing_key.#"

      GorgService.configuration=nil
      GorgService.configure do |c|
        c.application_name="GoogleDirectoryDaemon-test"
        c.application_id=@app_id
        c.rabbitmq_host=RabbitmqConfig.value_at("r_host")
        c.rabbitmq_port=RabbitmqConfig.value_at("r_port")
        c.rabbitmq_user=RabbitmqConfig.value_at("r_user")
        c.rabbitmq_password=RabbitmqConfig.value_at("r_pass")
        c.rabbitmq_vhost=RabbitmqConfig.value_at("r_vhost")
        c.rabbitmq_queue_name=@queue_name #change queue to avoid collision between tests
        c.rabbitmq_exchange_name=@exchange_name
        c.rabbitmq_deferred_time=100
        c.rabbitmq_max_attempts=3
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
        @sender.send_message({test_data: "testing_message"},"my.testing_key.is.awesome")
        sleep(1)
        expect(handler.message.data).to eq({test_data: "testing_message"})
      end
    end

    describe "softfail" do
      let(:handler) {SoftfailMessageHandler}

      it "retry 3 times" do
        puts "test_id : #{test_id}"
        @sender.send_message({test_data: "testing_message"},"my.testing_key")

        sleep(1)

        expect(handler.message.data).to eq({test_data: "testing_message"})
        expect(handler.attempts).to eq(3)
      end
    end
  end
end