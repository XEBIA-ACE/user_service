# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordPolicy do
  describe ".violations" do
    it "returns no violations for a compliant password" do
      expect(described_class.violations("Str0ng!Pass")).to be_empty
    end

    it "reports each unmet rule" do
      expect(described_class.violations("short")).to contain_exactly(
        "must be at least 8 characters",
        "must include an uppercase letter",
        "must include a digit",
        "must include a special character"
      )
    end

    it "reports passwords that are too long" do
      expect(described_class.violations("Aa1!#{'a' * 125}")).to eq(["must be at most 128 characters"])
    end
  end

  describe ".to_h" do
    subject(:policy) { described_class.to_h }

    it "describes the policy for clients" do
      expect(policy).to include(
        min_length: 8,
        max_length: 128,
        required_classes: %w[lowercase uppercase digit special]
      )
      expect(policy[:rules]).to all(include(:id, :pattern, :message))
    end

    it "agrees with the model-level FORMAT regex" do
      %w[Str0ng!Pass weakpassword NoDigits!! nospecial1A].each do |password|
        rules_met = policy[:rules].all? { |rule| Regexp.new(rule[:pattern]).match?(password) }
        expect(rules_met).to eq(described_class::FORMAT.match?(password))
      end
    end
  end
end
