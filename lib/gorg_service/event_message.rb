class GorgService
  class EventMessage<Message

    def type
      "event"
    end

    def validate
      super
    end

  end
end