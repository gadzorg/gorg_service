require 'spec_helper'
require 'json'
require "json-schema"


describe GorgService::Message do

  fake(:softfail_error,
    type: "softerror",
    message: "test_error",
    error_raised: StandardError.new("This is the runtime error")) {GorgService::SoftfailError}

  it "log errors" do

    msg=GorgService::Message.new()

    msg.log_error(softfail_error)
    expect(msg.errors.count).to eq(1)
    expect(msg.errors.first).to have_attributes(type: "softerror",
                                                message:"test_error",
                                                debug: an_instance_of(Hash))
    expect(msg.errors.first.debug[:internal_error]).to include("StandardError")
    expect(msg.errors.first.debug[:internal_error]).to include("This is the runtime error")
  end

  describe "parse JSON" do

    it "raise an error on unparsable JSON" do
      json="{invalid json"

      expect { GorgService::Message.parse(nil,nil,json) }.to raise_error(GorgService::HardfailError)
    end

    it "raise an error on invalid JSON based on json SCHEMA" do
      json='{"state":"invalid"}'
      expect { GorgService::Message.parse(nil,nil,json) }.to raise_error(GorgService::HardfailError)
    end


    it "return a message on valid JSON" do
      json={
        "event_uuid" => "88d818a1-c77c-44e6-ad0c-8aa893468e94",
        "event_name" => "testing_key",
        "event_creation_time" => "2016-05-29T15:03:50+00:00",
        "event_sender_id" => "tester",
        "data" => {
          "test_data" => "testing_message"
        },
        "errors_count" => 1,
        "errors" => [
          {
            "error_type" => "softerror",
            "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
            "error_sender" => "a_sender",
            "error_message" => "test_error",
            "timestamp" => "2016-05-29T15:03:50Z",
            "error_debug" => {}
            }
          ]
      }.to_json

        msg=GorgService::Message.parse({routing_key:"testing_key"},{headers:nil},json)

        expect(msg.id).to eq("88d818a1-c77c-44e6-ad0c-8aa893468e94")
        expect(msg.event).to eq("testing_key")
        expect(msg.creation_time).to eq(DateTime.new(2016,5,29,15,03,50))
        expect(msg.sender).to eq("tester")
        expect(msg.data).to eq({"test_data":"testing_message"})
        expect(msg.errors.count).to eq(1)
        expect(msg.errors.first).to have_attributes(type: "softerror",
                                                message:"test_error",
                                                debug: {},
                                                id:"88d838a1-c77c-44e6-ad0c-8aa893468e94",
                                                sender:"a_sender",
                                                timestamp:DateTime.new(2016,5,29,15,03,50))
    end
  end

  describe "returns its JSON format" do

    let(:json_msg) {msg.to_json}
    let(:msg) {GorgService::Message.new(
          id: "88d818a1-c77c-44e6-ad0c-8aa893468e94",
          event: "testing_key",
          sender: "tester",
          creation_time: DateTime.new(2016,5,29,15,03,50),
          data:{"test_data":"testing_message"},
          errors:[
            GorgService::Message::ErrorLog.new(
                type: "softerror",
                id: "88d838a1-c77c-44e6-ad0c-8aa893468e94",
                sender:  "a_sender",
                message: "test_error",
                timestamp: DateTime.new(2016,5,29,15,03,50),
                debug: {}
              )
          ]
        )}

    it "is valid against JSON schema" do

      expect(JSON::Validator.fully_validate(GorgService::Message::JSON_SCHEMA,json_msg)).to match_array([])
    end

    it "returns its data" do
      json={
        "event_uuid" => "88d818a1-c77c-44e6-ad0c-8aa893468e94",
        "event_name" => "testing_key",
        "event_creation_time" => "2016-05-29T15:03:50+00:00",
        "event_sender_id" => "tester",
        "data" => {
          "test_data" => "testing_message"
        },
        "errors_count" => 1,
        "errors" => [
          {
            "error_type" => "softerror",
            "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
            "error_sender" => "a_sender",
            "error_message" => "test_error",
            "timestamp" => "2016-05-29T15:03:50+00:00",
            "error_debug" => {}
            }
          ]
      }
      expect(JSON.parse(msg.to_json)).to eq(json)
    end

  end

end

