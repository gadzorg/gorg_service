require 'spec_helper'

describe GorgService::FailError do

  describe GorgService::SoftfailError do

    it "has the softerror type" do
      expect(GorgService::SoftfailError.new.type).to eq('softerror')
    end

  end

  describe GorgService::HardfailError do

    it "has the harderror type" do
      expect(GorgService::HardfailError.new.type).to eq('harderror')
    end

  end

end