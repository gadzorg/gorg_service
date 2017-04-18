require 'spec_helper'
require 'json'
require "json-schema"

describe GorgService::Message::FormatterV1 do

  describe "formatting" do

  end

  describe "parsing" do

    subject{GorgService::Message::FormatterV1}

    #Should be a Bunny::DeliveryInfo but interface for our usage is the same as Hash
    let(:delivery_info) {{ routing_key: "event.gram.user.deleted" }}
    #Should be a Bunny::MessageProperties but interface for our usage is the same as Hash
    let(:properties) {{
        # content_type: 'application/json',
        # content_encoding: 'deflate',
        # headers: {
        #     'soa-version' => 1.0,
        #     'client-library' => "GorgService #{GorgService::VERSION}",
        # },
        delivery_mode: 2,
        priority: 0,
        #message_id: 'ae027dee-bfcc-41d7-8f96-9bd9e324101f',
        #app_id: 'test_app',
    }}
    let(:body) {'{"event_uuid":"4c2742d3-8fe4-4f9b-9be6-306d2030da5e","event_name":"event.gram.user.deleted","event_sender_id":"gs","event_creation_time":"2017-04-04T13:50:15+02:00","data":{"id": "123465"}}'}

    describe "invalid payload" do
      context "non parsable JSON" do
        let(:body) {"not a json"}

        it "raise an Hardfail" do
          expect{subject.parse(delivery_info, properties, body)}.to raise_exception(GorgService::Consumer::HardfailError)
        end

      end
      context "invalid payload schema" do
        let(:body) {"{'some':'json'}"}

        it "raise an Hardfail" do
          expect{subject.parse(delivery_info, properties, body)}.to raise_exception(GorgService::Consumer::HardfailError)
        end
      end
    end

    describe "valid payload" do
      let(:message) {subject.parse(delivery_info, properties, body)}

      it "returns a message" do
        expect(message).to be_a_kind_of GorgService::Message
      end

      it "set default values" do
        expect(message).to have_attributes(content_type: nil, content_encoding: nil, soa_version: "1.0",type: nil)
      end

      it "set values" do
        expect(message).to have_attributes(
                               routing_key: "event.gram.user.deleted",
                               sender_id: "gs",
                               id: "4c2742d3-8fe4-4f9b-9be6-306d2030da5e",
                               data: {id: "123465"},
                               creation_time: DateTime.parse("2017-04-04T13:50:15+02:00")
                           )
      end

    end
  end
end