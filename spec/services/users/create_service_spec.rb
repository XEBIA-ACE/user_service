# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::CreateService do
  subject(:service) { described_class.new(params) }

  let(:valid_params) do
    {
      email: "newuser@example.com",
      username: "newuser",
      first_name: "New",
      last_name: "User",
      password: "Password1234!",
      password_confirmation: "Password1234!"
    }
  end

  describe "#call" do
    context "with valid params" do
      let(:params) { valid_params }

      it "returns a successful result" do
        result = service.call
        expect(result).to be_success
      end

      it "creates a user record" do
        expect { service.call }.to change(User, :count).by(1)
      end

      it "sets user status to pending" do
        result = service.call
        expect(result.payload.status).to eq("pending")
      end

      it "returns the created user in payload" do
        result = service.call
        expect(result.payload).to be_a(User)
        expect(result.payload.email).to eq("newuser@example.com")
      end
    end

    context "with missing required params" do
      let(:params) { valid_params.except(:email) }

      it "returns a failure result" do
        result = service.call
        expect(result).to be_failure
      end

      it "does not create a user" do
        expect { service.call }.not_to change(User, :count)
      end

      it "includes validation errors" do
        result = service.call
        expect(result.errors).not_to be_empty
      end
    end

    context "with duplicate email" do
      let(:params) { valid_params }

      before { create(:user, email: "newuser@example.com") }

      it "returns a failure result" do
        result = service.call
        expect(result).to be_failure
      end
    end

    context "with weak password" do
      let(:params) { valid_params.merge(password: "weak", password_confirmation: "weak") }

      it "returns a failure result" do
        result = service.call
        expect(result).to be_failure
      end
    end
  end
end
