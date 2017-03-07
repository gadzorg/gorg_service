class BunnyCleaner

  class Session
    def initialize(*args, &block)
      @target=Bunny::Session.new(*args,&block)
    end

    def method_missing(method, *args, &block)
      @target.send(method, *args, &block)
    end

    def self.method_missing(method, *args, &block)
      Bunny::Session.send(method, *args, &block)
    end

    def create_channel(*args,&block)
      ch=@target.create_channel(*args,&block)
      BunnyCleaner.registered_channels<<ch
      ch
    end
  end


  def initialize(*args, &block)
    @target=Session.new(*args, &block)
  end

  def method_missing(method, *args, &block)
    @target.send(method, *args, &block)
  end

  def self.method_missing(method, *args, &block)
    Bunny.send(method, *args, &block)
  end

  class << self
    def registered_channels
      @registered_channels||=[]
    end

    def cleaning(&block)
      begin
        init_cleaning
        block.call
      ensure
        clean
      end
    end


    def clean
      connections=[]
      @registered_channels.each do |ch|
        c=ch.connection
        connections<<c
        c.start unless c.status == :open

        c.with_channel do |chan|
          ch.queues.keys.each{|q| c.queue_exists?(q)&&chan.queue_delete(q) }
          ch.exchanges.keys.each{|ex| c.exchange_exists?(ex)&&chan.exchange_delete(ex) }
        end
      end
      connections.uniq.each{|c|c.stop}
    end

    def init_cleaning
      registered_channels.clear
    end

  end

end