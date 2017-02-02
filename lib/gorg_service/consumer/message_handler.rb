#!/usr/bin/env ruby
# encoding: utf-8

class GorgService
  class Consumer
    module MessageHandler

    end
  end
end

require "gorg_service/consumer/message_handler/base"
require "gorg_service/consumer/message_handler/event_handler"
require "gorg_service/consumer/message_handler/request_handler"
require "gorg_service/consumer/message_handler/reply_handler"