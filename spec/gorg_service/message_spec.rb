require 'spec_helper'
require 'json'



describe GorgService::Message do

  fake(:softfail_error,
    type: "softfail",
    message: "test_error",
    error_raised: StandardError.new("This is the runtime error")) {GorgService::SoftfailError}

  it "log errors" do

    msg=GorgService::Message.new()

    msg.log_error(softfail_error)
    expect(msg.errors.count).to eq(1)
    expect(msg.errors.first[:type]).to eq("softfail")
    expect(msg.errors.first[:message]).to eq("test_error")
    expect(msg.errors.first[:extra]).to include("StandardError")
    expect(msg.errors.first[:extra]).to include("This is the runtime error")
  end

  it "parse JSON" do
    json={
      "id":"88d818a1-c77c-44e6-ad0c-8aa893468e94",
      "event":"testing_key",
      "data":{
        "test_data":"testing_message"
        },
      "errors_count":1,
      "errors":[
        {
          "type":"softfail",
          "message":"test_error",
          "timestamp":"2016-05-29T15:03:50Z",
          "extra":""
          }
        ]
        }.to_json

      msg=GorgService::Message.parse_body(json)

      expect(msg.id).to eq("88d818a1-c77c-44e6-ad0c-8aa893468e94")
      expect(msg.event).to eq("testing_key")
      expect(msg.data).to eq({"test_data":"testing_message"})
      expect(msg.errors.count).to eq(1)
      expect(msg.errors.first[:type]).to eq("softfail")
      expect(msg.errors.first[:message]).to eq("test_error")
      expect(msg.errors.first[:extra]).to eq("")
      expect(msg.errors.first[:timestamp]).to eq(DateTime.new(2016,5,29,15,03,50))
  end

  it "returns its JSON format" do
    msg=GorgService::Message.new(
        id: "88d818a1-c77c-44e6-ad0c-8aa893468e94",
        event: "testing_key",
        data:{"test_data":"testing_message"},
        errors:[
          {
            "type":"softfail",
            "message":"test_error",
            "timestamp":"2016-05-29T15:03:50Z",
            "extra":""
          }
        ]
      )

    json={
      "id":"88d818a1-c77c-44e6-ad0c-8aa893468e94",
      "event":"testing_key",
      "data":{
        "test_data":"testing_message"
        },
      "errors_count":1,
      "errors":[
        {
          "type":"softfail",
          "message":"test_error",
          "timestamp":"2016-05-29T15:03:50Z",
          "extra":""
          }
        ]
        }.to_json


    expect(msg.to_json).to eq(json)
  end


end