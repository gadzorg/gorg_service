#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'time'
require 'json-schema'

require "gorg_service/message/json_schema"

class GorgService
  class Message

    attr_accessor :event
    attr_accessor :id
    attr_accessor :data
    attr_accessor :errors
    attr_accessor :creation_time
    attr_accessor :sender

    def errors
      @errors||=[]
    end


    def initialize(id: generate_id, data: nil, event: nil, creation_time: DateTime.now.iso8601, sender: application_id ,  errors: [])
      @id=id
      @event=event
      @data=data
      @errors=errors
      @creation_time=creation_time
      @sender= sender
    end

    # Generate RabbitMQ message body
    def to_json
      body={
        event_uuid: @id,
        event_name: @event,
        event_sender_id: @sender,
        event_creation_time: @creation_time,
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
      hsh={
            error_type: error.type.downcase,
            error_uuid: generate_id,
            error_sender: application_id ,
            error_message: error.message||"",
            timestamp: DateTime.now.iso8601,
            error_debug: {internal_error: error.error_raised.inspect},
          }
      hsh[:error_debug] = {internal_error: error.error_raised.inspect} if error.error_raised
      errors<<hsh
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

        JSON::Validator.validate!(GorgService::Message::JSON_SCHEMA,json_body)

        msg=self.new(
            id: json_body["event_uuid"],
            event: json_body["event_name"],
            data: convert_keys_to_sym(json_body["data"]),
            creation_time: json_body["event_creation_time"] && DateTime.parse(json_body["event_creation_time"]),
            sender: json_body["event_sender_id"],
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
      SecureRandom.uuid()
    end

    def application_id
      GorgService.configuration.application_id
    end

   

  end
end