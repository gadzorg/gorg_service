class LogMessageHandler < GorgService::Consumer::MessageHandler::Base
  def initialize(msg)
    GorgService.logger.debug "Message received in LogMessageHandler"
    self.class.messages<<msg
  end

  def self.messages
    @@messages||=[]
  end

  def self.has_received_error?(type)
    messages.any?{|m| m.errors.any?{|x| x.type==type}} || messages.any?{|m| m.type=='log'&&m.error_type=type}
  end

  def self.has_received_hardfail?
    self.has_received_error?("hardfail")
  end

  def self.has_received_softfail?
    self.has_received_error?("softfail")
  end

  def self.has_received_a_message_with_routing_key?(routing_key)
    messages.any?{|m| m.routing_key==routing_key}
  end

  def self.reset
    @@messages=nil
  end
end