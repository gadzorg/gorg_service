require 'spec_helper'

describe GorgService::MessageRouter do

  describe "routing" do

    it "convert keys to regex" do
      l= GorgService::MessageRouter

      expect(l.send(:amqp_key_to_regex,"agoram.users.create").match("agoram.users.create")).to    be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.users.create").match("agoram.gapps.create")).to    be_falsey
      expect(l.send(:amqp_key_to_regex,"agoram.*.create").match("agoram.users.create")).to        be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.*.create").match("agoram.g4pps.create")).to        be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.*.create").match("agoram.users.new.create")).to    be_falsey
      expect(l.send(:amqp_key_to_regex,"agoram.#.create").match("agoram.g4pps.create")).to        be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.#.create").match("agoram.us3rs.new.create")).to    be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.#.create").match("agoram.create")).to              be_truthy
      expect(l.send(:amqp_key_to_regex,"*.users.create").match("agoram.users.create")).to         be_truthy
      expect(l.send(:amqp_key_to_regex,"*.users.create").match("agoram.new.users.create")).to     be_falsey
      expect(l.send(:amqp_key_to_regex,"#.users.create").match("agoram.users.create")).to         be_truthy
      expect(l.send(:amqp_key_to_regex,"#.users.create").match("agoram.new.users.create")).to     be_truthy
      expect(l.send(:amqp_key_to_regex,"#.users.create").match("users.create")).to                be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.users.*").match("agoram.users.create")).to         be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.users.*").match("agoram.users.create.new")).to     be_falsey
      expect(l.send(:amqp_key_to_regex,"agoram.users.#").match("agoram.users.create")).to         be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.users.#").match("agoram.users.create.new")).to     be_truthy
      expect(l.send(:amqp_key_to_regex,"agoram.users.#").match("agoram.users")).to                be_truthy
    end

  end


end