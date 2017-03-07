class LogMessageHandler < GorgService::Consumer::MessageHandler::Base
  def initialize(msg)
    GorgService.logger.debug "Message received in LogMessageHandler"
    self.class.messages<<msg
  end

  def self.messages
    @@messages||=[]
  end

  def self.has_received_error?(type)
    messages.any?{|m| m.errors.any?{|x| x.type==type}}
  end

  def self.has_received_hardfail?
    self.has_received_error?("harderror")
  end

  def self.has_received_hardfail?
    self.has_received_error?("softerror")
  end

  def self.has_received_a_message_with_routing_key?(routing_key)
    messages.any?{|m| m.routing_key==routing_key}
  end

  def self.reset
    @@messages=nil
  end
end