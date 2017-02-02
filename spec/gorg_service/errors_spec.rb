require 'spec_helper'

describe GorgService::Consumer::FailError do

  describe GorgService::Consumer::SoftfailError do

    it "has the softerror type" do
      expect(GorgService::Consumer::SoftfailError.new.type).to eq('softerror')
    end

  end

  describe GorgService::Consumer::HardfailError do

    it "has the harderror type" do
      expect(GorgService::Consumer::HardfailError.new.type).to eq('harderror')
    end

  end

end