require 'spec_helper'
require 'json'

describe GorgService::Message::ErrorLog do

  it "is initializable" do
    error_log=GorgService::Message::ErrorLog.new( type: "warning",
                                        id: "ae11e852-2732-11e6-b67b-9e71128cae77",
                                        sender: "my_app" ,
                                        message: "This is an error !",
                                        timestamp: DateTime.new(2016,5,29,15,03,50),
                                        debug: {internal_error: "error"})

    expect(error_log).to have_attributes(type: "warning",
                                        id: "ae11e852-2732-11e6-b67b-9e71128cae77",
                                        sender: "my_app" ,
                                        message: "This is an error !",
                                        timestamp: DateTime.new(2016,5,29,15,03,50),
                                        debug: {internal_error: "error"})
  end

  it "has default values" do
    error_log=GorgService::Message::ErrorLog.new()
    expect(error_log).to have_attributes(type: "info",
                                        id: a_string_matching(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/),
                                        sender: GorgService.configuration.application_id ,
                                        message: "",
                                        timestamp: an_instance_of(DateTime),
                                        debug: {})
  end

  it "parse JSON string" do
    json={"error_type" => "softerror",
          "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
          "error_sender" => "a_sender",
          "error_message" => "test_error",
          "timestamp" => "2016-05-29T15:03:50Z",
          "error_debug" => {}
          }.to_json
    error_log=GorgService::Message::ErrorLog.parse(json)
    expect(error_log).to have_attributes(type: "softerror",
                                        id: "88d838a1-c77c-44e6-ad0c-8aa893468e94",
                                        sender: "a_sender" ,
                                        message: "test_error",
                                        timestamp: DateTime.new(2016,5,29,15,03,50),
                                        debug: {})
  end

  it "parse hash" do
    json={"error_type" => "softerror",
          "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
          "error_sender" => "a_sender",
          "error_message" => "test_error",
          "timestamp" => "2016-05-29T15:03:50Z",
          "error_debug" => {}
          }
    error_log=GorgService::Message::ErrorLog.parse(json)
    expect(error_log).to have_attributes(type: "softerror",
                                        id: "88d838a1-c77c-44e6-ad0c-8aa893468e94",
                                        sender: "a_sender" ,
                                        message: "test_error",
                                        timestamp: DateTime.new(2016,5,29,15,03,50),
                                        debug: {})
  end

  it "render a hash" do
    error_log=GorgService::Message::ErrorLog.new(
      type: "softerror",
      id: "88d838a1-c77c-44e6-ad0c-8aa893468e94",
      sender: "a_sender" ,
      message: "test_error",
      timestamp: DateTime.new(2016,5,29,15,03,50),
      debug: {})
    expect(error_log.to_h).to eq({"error_type" => "softerror",
          "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
          "error_sender" => "a_sender",
          "error_message" => "test_error",
          "timestamp" => "2016-05-29T15:03:50+00:00",
          "error_debug" => {}
          })
  end

  it "render a json" do
    error_log=GorgService::Message::ErrorLog.new(
      type: "softerror",
      id: "88d838a1-c77c-44e6-ad0c-8aa893468e94",
      sender: "a_sender" ,
      message: "test_error",
      timestamp: DateTime.new(2016,5,29,15,03,50),
      debug: {})
    expect(error_log.to_json).to eq({"error_type" => "softerror",
          "error_uuid" => "88d838a1-c77c-44e6-ad0c-8aa893468e94",
          "error_sender" => "a_sender",
          "error_message" => "test_error",
          "timestamp" => "2016-05-29T15:03:50+00:00",
          "error_debug" => {}
          }.to_json)
  end





end
