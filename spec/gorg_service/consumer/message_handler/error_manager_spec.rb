require 'spec_helper'

class TestException1 < StandardError;
end
class SpecialTestException1 < TestException1;
end
class TestException2 < StandardError;
end


describe GorgService::Consumer::MessageHandler::ExceptionManager do

  subject { GorgService::Consumer::MessageHandler::ExceptionManager.new }

  describe "returns an instance singleton" do
    it "returns an ExceptionManager" do
      expect(GorgService::Consumer::MessageHandler::ExceptionManager.instance).to be_a(GorgService::Consumer::MessageHandler::ExceptionManager)
    end

    it "is a singleton" do
      instance=GorgService::Consumer::MessageHandler::ExceptionManager.instance
      expect(GorgService::Consumer::MessageHandler::ExceptionManager.instance).to eq(instance)
    end
  end

  it "set a new rescuable excpetion" do
    subject.set_rescue_from TestException1, TestException2 do |e, message|
      puts "Error #{e.name} from #{message.id}"
    end

    expect(subject.rescuable_exceptions).to include(TestException1, TestException2)
  end

  describe "returns block for an exception" do
    it "simple case" do
      my_block=Proc.new { puts "coucou" }
      subject.set_rescue_from TestException1, &my_block
      expect(subject.get_rescue_block_for(TestException1.new)).to eq(my_block)
    end

    it "returns block for children classes" do
      my_block=Proc.new { puts "coucou" }
      subject.set_rescue_from TestException1, &my_block
      expect(subject.get_rescue_block_for(SpecialTestException1.new)).to eq(my_block)
    end
  end

  describe "rescue from exceptions" do
    before(:each) do
      @is_rescued=false
      @message=nil
      @error_raised=nil

      subject.set_rescue_from(TestException1) do |error,message|
        @is_rescued=true
        @error_raised=error
        @message=message
      end

      @my_error=SpecialTestException1.new
      @my_message=GorgService::Message.new
      subject.with_exception_rescuing(@my_message) do
        raise @my_error
      end
    end

    it "trigger given block" do
      expect(@is_rescued).to be true
    end

    it "passes the error" do
      expect(@error_raised).to eq(@my_error)
    end

    it "passes the message" do
      expect(@message).to eq(@my_message)
    end

  end

end