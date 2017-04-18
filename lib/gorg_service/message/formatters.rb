#!/usr/bin/env ruby
# encoding: utf-8

class GorgService::Message
    class Formatter

      def initialize(message)
        @message=message
      end

      def message
        @message
      end

      def self.formatter_for_version(version)
        major_version=version.split('.')[0]
        case major_version
          when '1'
            FormatterV1
          when '2'
            FormatterV2
          else
            raise "Unknown Gorg SOA version"
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

    end

    class FormatterV1 < Formatter

      JSON_SCHEMA_V1 = JSON.parse('{
          "$schema": "http://json-schema.org/draft-04/schema#",
          "type": "object",
          "properties": {
            "event_name": {
              "type": "string",
              "pattern": "^[_a-z]+((\\.)?[_a-z]+)*$",
              "description": "Event type. Must match the routing key"
            },
            "event_uuid": {
              "type": "string",
              "description": "The unique identifier of this message as UUID",
              "pattern": "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
            },
            "event_creation_time": {
              "type": "string",
              "description": "Creation time in UTC ISO 8601 format",
              "pattern": "^([\\\+-]?\\\d{4}(?!\\\d{2}\\\b))((-?)((0[1-9]|1[0-2])(\\\3([12]\\\d|0[1-9]|3[01]))?|W([0-4]\\\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\\\d|[12]\\\d{2}|3([0-5]\\\d|6[1-6])))([T\\\s]((([01]\\\d|2[0-3])((:?)[0-5]\\\d)?|24\\\:?00)([\\\.,]\\\d+(?!:))?)?(\\\17[0-5]\\\d([\\\.,]\\\d+)?)?([zZ]|([\\\+-])([01]\\\d|2[0-3]):?([0-5]\\\d)?)?)?)?$"
            },
            "event_sender_id": {
              "type": "string",
              "description": "Producer that sent the original message"
            },
            "data": {
              "type": "object",
              "description": "Data used to process this message"
            },
            "errors_count": {
              "type": "integer",
              "description": "Helper for counting errors"
            },
            "errors": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "error_type": {
                    "enum": [  "debug", "info", "warning", "softerror", "harderror" ],
                    "description": "Type of error."
                  },
                  "error_sender": {
                    "type": "string",
                    "description": "Consummer that sent this error"
                  },
                  "error_code":{
                    "type":"string",
                    "description": "Optionnal error code from the consummer"
                  },
                  "error_uuid":{
                    "type":"string",
                    "description": "The unique identifier of this error as UUID",
                    "pattern": "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
                  },
                  "error_message":{
                    "type":"string",
                    "description": "Error explanation"
                  },
                  "timestamp": {
                    "type": "string",
                    "description": "Time of occuring error in UTC ISO 8601",
                    "pattern": "^([\\\+-]?\\\d{4}(?!\\\d{2}\\\b))((-?)((0[1-9]|1[0-2])(\\\3([12]\\\d|0[1-9]|3[01]))?|W([0-4]\\\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\\\d|[12]\\\d{2}|3([0-5]\\\d|6[1-6])))([T\\\s]((([01]\\\d|2[0-3])((:?)[0-5]\\\d)?|24\\\:?00)([\\\.,]\\\d+(?!:))?)?(\\\17[0-5]\\\d([\\\.,]\\\d+)?)?([zZ]|([\\\+-])([01]\\\d|2[0-3]):?([0-5]\\\d)?)?)?)?$"
                  },
                  "error_debug": {
                    "type": "object",
                    "description": "Complementary informations for debugging"
                  }
                },
                "additionalProperties": false,
                "required": [
                  "error_type",
                  "error_sender",
                  "timestamp",
                  "error_uuid",
                  "error_message"
                ]
              }
            }
          },
          "additionalProperties": false,
          "required": [
            "event_name",
            "event_uuid",
            "event_creation_time",
            "event_sender_id",
            "data"
          ]
        }')

      DEFAULT_HEADERS={
          "soa-version" => "1.0",
          "client-library" => "GorgService #{GorgService::VERSION}",
      }

      def properties
        {
            routing_key: message.routing_key,
            reply_to: message.reply_to,
            correlation_id: message.correlation_id,
            content_type: message.content_type,
            content_encoding: message.content_encoding,
            headers: DEFAULT_HEADERS.merge(message.headers.to_h).merge(
                'softfail-count' => message.softfail_count,
            ),
            app_id: message.sender_id,
            type: message.type,
            message_id: message.id,
        }
      end

      def body
        b={
            event_uuid: message.id,
            event_name: message.routing_key,
            event_sender_id: message.sender,
            event_creation_time: message.creation_time.iso8601,
            data: message.data,
        }
        if message.errors.any?
          b[:errors_count]=message.errors.count
          b[:errors]=message.errors.map{|e| e.to_h}
        end
        b
      end

      def payload
        body.to_json
      end

      def self.parse(delivery_info, properties, body)
        begin
          json_body=JSON.parse(body)
          JSON::Validator.validate!(JSON_SCHEMA_V1, json_body)

          msg=GorgService::Message.new(
              routing_key: delivery_info[:routing_key],
              reply_to: properties[:reply_to],
              correlation_id: properties[:correlation_id],
              sender_id: properties[:app_id],
              content_type: properties[:content_type],
              content_encoding: properties[:content_encoding],
              headers: properties[:headers],
              type: properties[:type],

              softfail_count: properties[:headers].to_h.delete('softfail-count'),

              id: json_body["event_uuid"],
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
          raise GorgService::Consumer::HardfailError.new("Invalid JSON : This message does not respect Gadz.org JSON Schema",e,{})
        end
      end
    end


    class FormatterV2 < Formatter

      DEFAULT_HEADERS={
          "soa-version" => "2.0",
          "client-library" => "GorgService #{GorgService::VERSION}",
      }

      EXTRA_HEADERS_FOR ={
          GorgService::ReplyMessage => {
              'status-code' => :status_code,
              'error-type' => :error_type,
              'next-try-in' => :next_try_in,
              'error-name' => :error_name,
          },
          GorgService::LogMessage => {
              'level' => :level,
              'error-type' => :error_type,
              'next-try-in' => :next_try_in,
              'error-name' => :error_name,
          },

      }

      def properties

        headers=DEFAULT_HEADERS.merge(message.headers.to_h).merge(
            'softfail-count' => message.softfail_count,
        )

        extra_headers=EXTRA_HEADERS_FOR[message.class].to_h.map do|key,method_name|
          [key,message.public_send(method_name)]
        end.to_h


        headers.merge!(extra_headers)

        {
            routing_key: message.routing_key,
            reply_to: message.reply_to,
            correlation_id: message.correlation_id,
            content_type: message.content_type,
            content_encoding: message.content_encoding,
            headers: headers,
            app_id: message.sender_id,
            type: message.type,
            message_id: message.id,
        }
      end

      def body
        message.data
      end

      def payload
        body.to_json
      end

      def self.parse(delivery_info, properties, body)
        begin

          type=properties[:type]
          unless type
            type=delivery_info[:routing_key].split('.').first
          end

          type_map={event: GorgService::EventMessage, request: GorgService::RequestMessage, reply: GorgService::ReplyMessage, log: GorgService::LogMessage}
          klass=type_map[type.to_s.to_sym]

          raise "Unknown type" unless klass

          headers=properties[:headers]||{}

          args={
              data: convert_keys_to_sym(JSON.parse(body)),
              id:properties[:message_id],

              creation_time: properties[:timestamp] && DateTime.parse(properties[:timestamp]),
              sender:properties[:app_id],
              routing_key: delivery_info[:routing_key],

              reply_to: properties[:reply_to],
              correlation_id: properties[:correlation_id],
              content_type: properties[:content_type],
              content_encoding:properties[:content_encoding],
              soa_version: headers.delete('soa-version'),

              softfail_count: headers.delete('softfail-count'),

              headers: headers,
          }

          extra_args=EXTRA_HEADERS_FOR[klass].to_h.map do |key,method_name|
            [method_name,headers.delete(key)]
          end.to_h

          args.merge!(extra_args)

          klass.new(args)
        rescue JSON::ParserError => e
          raise GorgService::Consumer::HardfailError.new("Unprocessable message : Unable to parse JSON message body", e)
        rescue JSON::Schema::ValidationError => e
          raise GorgService::Consumer::HardfailError.new("Invalid JSON : This message does not respect Gadz.org JSON Schema",e)
        end
      end

    end
end
