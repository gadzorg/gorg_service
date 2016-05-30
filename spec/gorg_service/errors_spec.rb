require 'spec_helper'

describe GorgService::FailError do

  describe GorgService::SoftfailError do

    it "has the softfail type" do
      expect(GorgService::SoftfailError.new.type).to eq('softfail')
    end

  end

  describe GorgService::HardfailError do

    it "has the hardfail type" do
      expect(GorgService::HardfailError.new.type).to eq('hardfail')
    end

  end

end