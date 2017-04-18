#!/usr/bin/env ruby
# encoding: utf-8
require 'json'
require 'time'
require 'json-schema'
require 'securerandom'

require "gorg_service/message/json_schema"
require "gorg_service/message/error_log"

require "gorg_service/reply_message"
require "gorg_service/event_message"
require "gorg_service/log_message"
require "gorg_service/request_message"

require "gorg_service/message/formatters"



# Message transferred through Bunny. Follow Gorg SOA specification v2.0 ans maintain support for v1.0
#
# @author Alexandre Narbonne
class GorgService
  class Message

    DEFAULT_SOA_VERSION="1.0"

    class DataValidationError < StandardError

      # @return [Hash] Mapping of invalid data
      attr_reader :errors

      def initialize(errors)
        @errors=errors
      end
    end

    class MessageValidationError < StandardError

      # @return [Hash] Mapping of invalid data
      attr_reader :errors

      def initialize(errors)
        @errors=errors
      end
    end

    # @return [String] UUID of  the message
    attr_accessor :id

    # @return [String] Id of the app which generated the message
    attr_accessor :sender_id
    alias_method :sender, :sender_id
    alias_method :sender=, :sender_id=

    # @return [String] Content type of the payload
    # @note The only content type officially supported by Gadz.org SOA is 'application/json'
    attr_accessor :content_type

    # @return [String] Content encoding of the payload
    # @note The only content encoding officially supported by Gadz.org SOA is 'deflate'
    attr_accessor :content_encoding

    # @return [String] The Gadz.org SOA specs version used to generate this message
    # @note Incomming message without this information should be considered v1.0
    attr_accessor :soa_version

    # @return [String] Major version of the soa version
    def soa_version_major
      (self.soa_version||DEFAULT_SOA_VERSION).split('.')[0]
    end

    # @return [String] identifier of the library used to generate this message, for debug and compatibility purpose
    attr_accessor :client_library

    # @return [String] Identifier of the admin who triggered the generation of this message
    # @note In case of autonomous actions, there is no admin_id
    attr_accessor :admin_id

    # @return [String] Routing of the message
    attr_accessor :routing_key

    # @return [Hash] Data of the payload as an hash
    # @note for further compatibility, don't assume that data is an hash but check Content-Type
    attr_accessor :data

    # @return [DateTime] Message generation datetime
    attr_accessor :creation_time

    # @return [String] Name of the exchange used to receive reply
    attr_accessor :reply_to
    alias_method :reply_exchange, :reply_to

    # @return [String] UUID of the message the this message refer to (reply or log)
    attr_accessor :correlation_id

    # @return [nil] Type of message (event,log,request,reply). To be overwritten by children classes
    def type
      nil
    end

    # @return [Hash] Additional headers
    attr_accessor :headers

    # @return [Integer] Number of softfails associated to this message
    attr_accessor :softfail_count

    # @deprecated In Gadz.org Soa v2.0 errors are not store in messages anymore
    # @return [Array<Message::ErrorLog>] List of errors associated to this message
    attr_accessor :errors

    # @return [Hash] Mapping of attributes errors in regard of Gadz.org SOA v2
    attr_accessor :validation_errors
    def validation_errors
      @validation_errors||= Hash.new([].freeze)
    end

    # @deprecated Use {#routing_key} instead. event is no longer a part of GorgSOA specs
    # @return [String] the name of the event
    attr_accessor :event
    def event
      warn "[DEPRECATION] Message.event is deprecated and will be removed soon. Use id instead (called from #{caller_locations(1,1)[0]})"
      self.routing_key
    end
    def event=(value)
      warn "[DEPRECATION] Message.event is deprecated and will be removed soon. Use id instead  (called from #{caller_locations(1,1)[0]})"
      self.routing_key=value
    end



    # @deprecated Use {#id} instead. event_id is no longer a part of GorgSOA specs
    # @return [String] UUID of  the message
    attr_accessor :event_id
    def event_id
      warn "[DEPRECATION] Message.event_id is deprecated and will be removed soon. Use id instead  (called from #{caller_locations(1,1)[0]})"
      self.id
    end
    def event_id=(value)
      warn "[DEPRECATION] Message.event_id is deprecated and will be removed soon. Use id instead  (called from #{caller_locations(1,1)[0]})"
      self.id=value
    end

    # @deprecated In Gadz.org Soa v2.0 errors are not store in messages anymore
    # @return [Array<Message::ErrorLog>] List of errors associated to this message
    def errors
      @errors||=[]
    end

    # @param opts [Hash] Attributes of the message
    # @option opts [String] :id See {#id}. Default : Random UUID4
    # @option opts [Array<Message::ErrorLog>] :errors  See {#errors}. Default : []
    # @option opts [DateTime] :creation_time See {#creation_time}. Default :  DateTime.now
    # @option opts [String] :sender See {#sender}. Default : GorgService.configuration.application_id
    # @option opts [String] :data See {#data}. Default : nil
    # @option opts [String] :routing_key See {#routing_key}. Default : nil
    # @option opts [String] :reply_to See {#reply_to}. Default : nil
    # @option opts [String] :correlation_id See {#correlation_id}. Default : nil
    # @option opts [String] :content_type See {#content_type}. Default : "application/json"
    # @option opts [String] :content_encoding See {#content_encoding}. Default : "deflate"
    # @option opts [String] :headers See {#headers}. Default : {}
    def initialize(opts={})
      self.id= opts.fetch(:event_id,nil)||opts.fetch(:id,generate_id)

      self.errors= opts.fetch(:errors,[])
      self.creation_time= opts.fetch(:creation_time,DateTime.now)
      self.sender= opts.fetch(:sender,application_id)
      self.data= opts.fetch(:data,nil)
      self.routing_key= opts.fetch(:routing_key,nil)||opts.fetch(:event,nil)
      self.softfail_count= opts.fetch(:softfail_count,0)

      self.reply_to= opts.fetch(:reply_to,nil)
      self.correlation_id= opts.fetch(:correlation_id,nil)
      self.content_type= opts.fetch(:content_type,"application/json")
      self.content_encoding= opts.fetch(:content_encoding,"deflate")
      self.headers= opts.fetch(:headers,{})
      self.soa_version= opts.fetch(:soa_version, DEFAULT_SOA_VERSION)
    end

    # @deprecated Please use directly the rendering interface of the formatter
    # @param formatter [Message::FormatterV1] The formatter to be used. Default : an instance of Message::FormatterV1
    # @return [Hash] The un-serialized payload of the RabbitMq message
    def body
      Message::Formatter.formatter_for_version(self.soa_version).new(self).body
    end
    alias_method :to_h, :body
    alias_method :payload, :body

    # @deprecated Please use directly the rendering interface of the formatter
    # @param formatter [Message::FormatterV1] The formatter to be used. Default : an instance of Message::FormatterV1
    # @return [Hash] The properties of the RabbitMq message
    def properties(formatter: Message::FormatterV1.new(self))
      Message::Formatter.formatter_for_version(self.soa_version).new(self).properties
    end

    # @return [String] The serialized (JSON) value of the RabbitMQ payload
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

    # @return [Boolean] Does this message expect a reply ?
    def expect_reply?
      !!reply_to
    end

    # @return [Stirng] Routing key to use to reply to this message
    def reply_routing_key
      routing_key.sub('request','reply')
    end

    # @return [GorgService::ReplyMessage] the response to send

    def reply_message(opts)
      args= {
              routing_key: self.reply_routing_key,
              correlation_id: self.id,
              soa_version: self.soa_version
            }.merge(opts)

      GorgService::ReplyMessage.new(args)
    end

    def log_message(opts)
      args= {
          routing_key: self.reply_routing_key,
          correlation_id: self.id,
          soa_version: '2.0' #v1 messages generate v2 logs
      }.merge(opts)

      GorgService::LogMessage.new(args)
    end

    # Validate the message against rules specified in {https://confluence.gadz.org/display/INFRA/Messages the Gadz.org SOA Message Specification}
    def validate
      self.validation_errors= Hash.new([].freeze)

      self.validation_errors[:content_type]+=["is not supported by Gadz.org SOA"] unless ['application/json'].include? self.content_type
      self.validation_errors[:content_encoding]+=["is not supported by Gadz.org SOA"] unless ['deflate','gzip'].include? self.content_encoding
      # "gzip" is not officially supported by Gadz.org but I don't feel comfortable blocking it :)

      self.validation_errors[:id]+=["is null"] unless self.id
      self.validation_errors[:id]+=["is not a UUID"] unless !self.id ||  /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.match(self.id)

      self.validation_errors[:correlation_id]+=["is not a UUID"] unless !self.correlation_id || /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.match()

      self.validation_errors[:creation_time]+=["is not DateTime"] unless self.creation_time.is_a? DateTime

      self.validation_errors[:type]+=["is not in (event, log, request, reply)"] unless %w(event log request reply).include? self.type

      self.validation_errors[:sender]+=["is null"] unless self.sender

      self.validation_errors[:soa_version]+=["is null"] unless self.soa_version

      return self.validation_errors.empty?
    end
    alias_method :valid?, :validate

    # @see #validate
    # @raise [MessageValidationError] Raise an exception containing the errors if the message is invalid
    def validate!
      raise MessageValidationError.new(self.errors) unless validate
    end

    # @param [String,Hash] A JSON Schema usable by {JSON::Validator}
    # @return [Boolean] True if the message is valid against the provided JSON Schema
    # @raise [DataValidationError] Validation exception containing errors ( See {DataValidationError#errors})
    def validate_data_with(schema)
      data_validation_errors=JSON::Validator.fully_validate(schema, self.data)
      if data_validation_errors.any?
        raise DataValidationError.new(data_validation_errors)
      else
        return true
      end
    end



    ### Class methods

    # @param [Hash] delivery_info delivery_info provided by {Bunny}
    # @param [Hash] properties properties provided by {Bunny}
    # @param [Hash] body body provided by {Bunny}
    # @param [Class] formatter_class The formatter to be used to parse the message. Default to {Message::FormatterV1}
    # @return [GorgService::Message] A kind of GorgService::Message
    def self.parse(delivery_info, properties, body)
      formatter_class=Message::Formatter.formatter_for_version(properties.to_h[:headers].to_h["soa-version"]||"1")
      formatter_class.parse(delivery_info, properties, body)
    end

    protected
    # Generate new id
    def generate_id 
      SecureRandom.uuid()
    end

    def application_id
      GorgService.configuration.application_id
    end



  end
end