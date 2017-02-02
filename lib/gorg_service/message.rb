#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'time'
require 'json-schema'
require 'securerandom'

require "gorg_service/message/json_schema"
require "gorg_service/message/error_log"

class GorgService
  class Message

    attr_accessor :id
    attr_accessor :reply_to
    attr_accessor :correlation_id
    attr_accessor :sender_id
    attr_accessor :content_type
    attr_accessor :content_encoding
    attr_accessor :headers
    attr_accessor :type

    attr_accessor :event_id
    attr_accessor :routing_key
    attr_accessor :event
    attr_accessor :data
    attr_accessor :errors
    attr_accessor :creation_time
    attr_accessor :sender

    def errors
      @errors||=[]
    end


    def initialize(opts={})
      ##Message payload params
      @event_id= opts.fetch(:event_id,generate_id)
      @errors= opts.fetch(:errors,nil)
      @creation_time= opts.fetch(:creation_time,DateTime.now.iso8601)
      @sender= opts.fetch(:sender,application_id)
      @event= opts.fetch(:event,nil)
      @data= opts.fetch(:data,nil)

      #Message Attributes params
      @routing_key= opts.fetch(:routing_key,event)
      @id= opts.fetch(:id,generate_id)
      @reply_to= opts.fetch(:reply_to,nil)
      @correlation_id= opts.fetch(:correlation_id,nil)
      @sender_id= opts.fetch(:sender_id,application_id)
      @content_type= opts.fetch(:content_type,"application/json")
      @content_encoding= opts.fetch(:content_encoding,"deflate")
      @headers= opts.fetch(:headers,{})
      @type= opts.fetch(:type,"event")
    end

    def body
      _body={
        event_uuid: @event_id,
        event_name: @event,
        event_sender_id: @sender,
        event_creation_time: @creation_time,
        data: @data,
      }
      if errors.any?
        _body[:errors_count]=@errors.count
        _body[:errors]=@errors.map{|e| e.to_h}
      end
      _body
    end
    alias_method :to_h, :body
    alias_method :payload, :body

    def properties
      {
          routing_key: routing_key,
          reply_to: reply_to,
          correlation_id: correlation_id,
          content_type: content_type,
          content_encoding: content_encoding,
          headers: headers,
          app_id: sender_id,
          type: type,
          message_id: id,
      }
    end

    # Generate RabbitMQ message body
    def to_json
      self.to_h.to_json
    end

    # Log FailError in message body
    def log_error error
      e=GorgService::Message::ErrorLog.new(
        type: error.type.downcase,
        message: error.message||"",
        debug: error.error_raised && {internal_error: error.error_raised.inspect}
        )
      errors<<e
    end

    def reply_exchange
      reply_to
    end

    def expect_reply?
      !!reply_to
    end

    def reply_routing_key
      event.sub('request','reply')
    end

    ### Class methods

    def self.parse(delivery_info, properties, body)
      begin
        json_body=JSON.parse(body)

        JSON::Validator.validate!(GorgService::Message::JSON_SCHEMA,json_body)

        msg=self.new(
            routing_key: delivery_info[:routing_key],
            id: properties[:message_id],
            reply_to: properties[:reply_to],
            correlation_id: properties[:correlatio_to],
            sender_id: properties[:app_id],
            content_type: properties[:content_type],
            content_encoding: properties[:content_encoding],
            headers: properties[:header],
            type: properties[:type],

            event_id: json_body["event_uuid"],
            event: json_body["event_name"],
            data: convert_keys_to_sym(json_body["data"]),
            creation_time: json_body["event_creation_time"] && DateTime.parse(json_body["event_creation_time"]),
            sender: json_body["event_sender_id"],
            errors: json_body["errors"]&&json_body["errors"].map{|e| GorgService::Message::ErrorLog.parse(e)},
        )
        msg
      rescue JSON::ParserError => e
        raise GorgService::Consumer::HardfailError.new("Unprocessable message : Unable to parse JSON message body", e)
      rescue JSON::Schema::ValidationError => e
        raise GorgService::Consumer::HardfailError.new("Invalid JSON : This message does not respect Gadz.org JSON Schema",e)
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