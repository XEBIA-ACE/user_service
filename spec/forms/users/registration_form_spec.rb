# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::RegistrationForm do
  let(:attributes) do
    {
      full_name: "  Ada   Lovelace ",
      email_address: " Ada@Example.COM ",
      password: "Str0ng!Pass",
      consent_accepted: true
    }
  end

  subject(:form) { described_class.new(**attributes) }

  it "is valid with complete, compliant data" do
    expect(form).to be_valid
  end

  it "normalises full name and email" do
    expect(form.full_name).to eq("Ada Lovelace")
    expect(form.email_address).to eq("ada@example.com")
  end

  it "rejects a whitespace-only full name" do
    attributes[:full_name] = "   "
    expect(form).not_to be_valid
    expect(form.errors[:full_name]).to include("can't be blank")
  end

  it "rejects an invalid email" do
    attributes[:email_address] = "not-an-email"
    expect(form).not_to be_valid
    expect(form.errors[:email_address]).to include("is not a valid email address")
  end

  it "reports each unmet password rule" do
    attributes[:password] = "password"
    expect(form).not_to be_valid
    expect(form.errors[:password]).to include(
      "must include an uppercase letter", "must include a digit", "must include a special character"
    )
  end

  [false, "false", nil, "", "1", "yes"].each do |value|
    it "rejects consent_accepted=#{value.inspect}" do
      attributes[:consent_accepted] = value
      expect(form).not_to be_valid
      expect(form.errors[:consent_accepted]).to include("must be accepted")
    end
  end

  describe ".schema" do
    subject(:schema) { described_class.schema }

    it "lists the registration fields in focus order" do
      expect(schema[:form][:fields].pluck(:name)).to eq(%w[full_name email_address password consent_accepted])
      expect(schema[:form][:fields]).to all(include(:label, :type, required: true))
    end

    it "includes the password policy" do
      expect(schema[:password_policy]).to eq(PasswordPolicy.to_h)
    end
  end
end
