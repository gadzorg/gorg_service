class GorgService
  class ReplyMessage<Message

    # @return [String] Error code, HTTP like
    attr_accessor :status_code

    # @return [String] Error type ('hardfail','softfail')
    attr_accessor :error_type

    # @return [Integer] Time until next attempts in milliseconds
    attr_accessor :next_try_in

    # @return [String] Name identifying the error
    attr_accessor :error_name

    def type
      "reply"
    end

    # @param opts [Hash] Attributes of the message
    # @option opts [String] :status_code See {#status_code}. Default : nil
    # @option opts [String] :error_type See {#error_type}. Default : nil
    # @option opts [Integer] :next_try_in See {#next_try_in}. Default : nil
    # @option opts [String] :error_name See {#error_name}. Default : nil
    # @see GorgService::Message#initialize
    def initialize(opts={})
      super
      self.status_code= opts.fetch(:status_code,nil)
      self.error_type=  opts.fetch(:error_type,nil)
      self.next_try_in= opts.fetch(:next_try_in,nil)
      self.error_name=  opts.fetch(:error_name,nil)
    end

    def validate
      self.validation_errors[:status_code]+=["is null"] unless self.status_code
      self.validation_errors[:error_type]+=["is not in (softfail hardfail)"] unless self.error_type && (%w(softfail hardfail).include? self.error_type)
      super
    end

  end
end