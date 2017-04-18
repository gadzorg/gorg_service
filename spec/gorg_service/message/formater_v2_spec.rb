require 'spec_helper'
require 'json'
require "json-schema"

describe GorgService::Message::FormatterV2 do

  describe "formatting" do

  end

  describe "parsing" do

    subject{GorgService::Message::FormatterV2}

    let(:type) {"event"}
    #Should be a Bunny::DeliveryInfo but interface for our usage is the same as Hash
    let(:delivery_info) {{ routing_key: "#{type}.some.routing.key" }}
    #Should be a Bunny::MessageProperties but interface for our usage is the same as Hash
    let(:properties) {
        common_properties
    }

    let(:common_properties) {{content_type: 'application/json',
                              content_encoding: 'deflate',
                              headers: {
                                  'soa-version' => 2.0,
                                  'client-library' => "GorgService #{GorgService::VERSION}",
                              },
                              delivery_mode: 2,
                              priority: 0,
                              message_id: 'ae027dee-bfcc-41d7-8f96-9bd9e324101f',
                              app_id: 'test_app',
                              timestamp: '2017-04-04T13:50:15+02:00',
                              type: type}}

    let(:body) {'{"id": "123465"}'}

    describe "invalid message" do
      context "non parsable JSON" do
        let(:body) {"not a json"}

        it "raise an Hardfail" do
          expect{subject.parse(delivery_info, properties, body)}.to raise_exception(GorgService::Consumer::HardfailError)
        end

      end
    end

    describe "valid message" do
      let(:message) {subject.parse(delivery_info, properties, body)}
      shared_examples "common parsing examples" do
        it "returns a message" do
          expect(message).to be_a_kind_of GorgService::Message
        end

        it "set common values" do
          expect(message).to have_attributes(
                                 sender_id: "test_app",
                                 id: "ae027dee-bfcc-41d7-8f96-9bd9e324101f",
                                 data: {id: "123465"},
                                 creation_time: DateTime.parse("2017-04-04T13:50:15+02:00"),
                                 event: "#{type}.some.routing.key"
                             )
        end
      end

      describe "event message" do
        let(:type) {"event"}

        include_examples "common parsing examples"

        it "returns an event message" do
          expect(message).to be_a_kind_of GorgService::EventMessage
        end
      end

      describe "request message" do
        let(:type) {"request"}

        include_examples "common parsing examples"

        it "returns a request message" do
          expect(message).to be_a_kind_of GorgService::RequestMessage
        end
      end

      describe "reply message" do
        let(:type) {"reply"}

        let(:properties) {
          common_properties.merge({
            headers: common_properties[:headers].merge({
                                                           'status-code'=>500,
                                                           'error-type' => 'softfail',
                                                           'next-try-in' => 3600000,
                                                           'error-name' => 'GramConnectionError',
                                                       })
          })
        }

        include_examples "common parsing examples"

        it "returns a reply message" do
          expect(message).to be_a_kind_of GorgService::ReplyMessage
        end

        it "set specifivc values" do
          expect(message).to have_attributes(
                                 status_code: 500,
                                 error_type: 'softfail',
                                 next_try_in: 3600000,
                                 error_name: 'GramConnectionError',
                             )
        end
      end

      describe "log message" do
        let(:type) {"log"}

        include_examples "common parsing examples"

        it "returns a log message" do
          expect(message).to be_a_kind_of GorgService::LogMessage
        end
      end

    end
  end
end