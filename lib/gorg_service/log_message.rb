class GorgService
  class LogMessage<Message
    # @return [String] Level of the log
    # 0 => DEBUG
    # 1 => INFO
    # 2 => WARNING
    # 3 => SOFTFAIL
    # 4 => HARDFAIL
    attr_accessor :level

    # @return [String] Error type ('hardfail','softfail')
    attr_accessor :error_type

    # @return [Integer] Time until next attempts in milliseconds
    attr_accessor :next_try_in

    # @return [String] Name identifying the error
    attr_accessor :error_name

    def type
      "log"
    end

    # @param opts [Hash] Attributes of the message
    # @option opts [String] :level See {#level}. Default : 1
    # @option opts [String] :error_type See {#error_type}. Default : nil
    # @option opts [Integer] :next_try_in See {#next_try_in}. Default : nil
    # @option opts [String] :error_name See {#error_name}. Default : nil
    # @see GorgService::Message#initialize
    def initialize(opts={})
      super
      self.level= opts.fetch(:level,1)
      self.error_type=  opts.fetch(:error_type,nil)
      self.next_try_in= opts.fetch(:next_try_in,nil)
      self.error_name=  opts.fetch(:error_name,nil)
    end

    def validate
      self.validation_errors[:level]+=["is null"] unless self.level
      self.validation_errors[:level]+=["is not in [0,1,2,3,4]"] unless (0..4).to_a.include?(self.level)
      self.validation_errors[:error_type]+=["is not in (softfail hardfail)"] unless self.error_type && (%w(softfail hardfail).include? self.error_type)
      super
    end

  end
end