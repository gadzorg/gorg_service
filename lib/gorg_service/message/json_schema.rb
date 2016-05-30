#!/usr/bin/env ruby
# encoding: utf-8

require 'json'

class GorgService
  class Message

    JSON_SCHEMA = JSON.parse('{
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

end
end