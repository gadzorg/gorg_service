#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'time'

class GorgService
  class Message

    attr_accessor :event
    attr_accessor :id
    attr_accessor :data
    attr_accessor :errors

    def errors
      @errors||=[]
    end


    def initialize(id: nil, data: nil, event: nil, errors: [])
      @id=id || generate_id
      @event=event
      @data=data
      @errors=errors
    end

    # Generate RabbitMQ message body
    def to_json
      body={
        id: @id,
        event: @event,
        data: @data,
      }
      if errors.any?
        body[:errors_count]=@errors.count
        body[:errors]=@errors
      end
      body.to_json
    end

    # Log FailError in message body
    def log_error error
      errors<<{
            type: error.type.downcase,
            message: error.message,
            timestamp: Time.now.utc.iso8601,
            extra: error.error_raised.inspect,
          }
    end

    ### Class methods

    # Parse RabbitMQ message body
    # @return Message
    #   parsed message
    # Errors
    #   Hardfail if un-parsable JSON body
    def self.parse_body(body)
      begin
        json_body=JSON.parse(body)

        msg=self.new(
            id: json_body["id"],
            event: json_body["event"],
            data: convert_keys_to_sym(json_body["data"]),
            errors: json_body["errors"]&&json_body["errors"].map{|e| convert_keys_to_sym(e)},
          )

        msg.errors=msg.errors.each do |e|
         e[:timestamp]=(e[:timestamp] ? DateTime.parse(e[:timestamp]) : nil)
        end
        msg
      rescue JSON::ParserError => e
        raise GorgService::HardfailError.new(e), "Unprocessable message : Unable to parse JSON message body"
      end
    end


    def self.convert_keys_to_sym input_hash
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

    private

    # Generate new id
    def generate_id 
      "#{GorgService.configuration.application_id}_#{Time.now.to_i}"
    end

   

  end
end