#!/usr/bin/env ruby
# encoding: utf-8

require 'json'
require 'securerandom'

class GorgService
  class Message
    class ErrorLog

      attr_accessor :type, :id, :sender, :message, :timestamp, :debug

      def initialize( type: "info",
                      id: SecureRandom.uuid,
                      sender: GorgService.configuration.application_id,
                      message: "",
                      timestamp: DateTime.now,
                      debug: {})
        @type=type
        @id=id
        @sender=sender
        @message=message
        @timestamp=timestamp
        @debug=debug
      end

      def to_h
        h={"error_type" => type,
          "error_uuid" => id,
          "error_sender" => sender,
          "error_message" => message,
          "timestamp" => timestamp.iso8601,
          }
        h["error_debug"]= debug if debug
        h
      end

      def to_json
        to_h.to_json
      end

      class << self
        def parse(obj)
          obj=JSON.parse(obj) unless obj.is_a? Hash

          obj=convert_keys_to_sym(obj)

          self.new( type: obj[:error_type],
                    id: obj[:error_uuid],
                    sender: obj[:error_sender],
                    message: obj[:error_message],
                    timestamp: DateTime.parse(obj[:timestamp]),
                    debug: obj[:error_debug])

        end

        protected

        def convert_keys_to_sym input_hash
          s2s = 
          lambda do |h| 
            Hash === h ? 
              Hash[
                h.map do |k, v| 
                  [k.respond_to?(:to_sym) ? k.to_sym : k, s2s[v]] 
                end 
              ] : h 
          end
          s2s[input_hash]
        end

      end

    end
  end
end
