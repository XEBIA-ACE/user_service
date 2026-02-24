# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::AuthService do
  let(:password) { "Password1234!" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  subject(:service) do
    described_class.new(
      email: user.email,
      password: password,
      ip_address: "127.0.0.1",
      user_agent: "RSpec"
    )
  end

  describe "#call" do
    context "with valid credentials" do
      it "returns a successful result" do
        expect(service.call).to be_success
      end

      it "returns access and refresh tokens" do
        result = service.call
        expect(result.payload[:access_token]).to be_present
        expect(result.payload[:refresh_token]).to be_present
      end

      it "creates a session record" do
        expect { service.call }.to change(UserSession, :count).by(1)
      end

      it "updates last_login_at" do
        service.call
        expect(user.reload.last_login_at).to be_within(2.seconds).of(Time.current)
      end
    end

    context "with wrong password" do
      subject(:service) do
        described_class.new(email: user.email, password: "WrongPassword!")
      end

      it "returns a failure" do
        expect(service.call).to be_failure
      end

      it "does not create a session" do
        expect { service.call }.not_to change(UserSession, :count)
      end

      it "increments failed_login_count" do
        expect { service.call }.to change { user.reload.failed_login_count }.by(1)
      end
    end

    context "with unknown email" do
      subject(:service) do
        described_class.new(email: "unknown@example.com", password: password)
      end

      it "returns a failure with a generic message" do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to eq("Invalid email or password")
      end
    end

    context "when account is locked" do
      let!(:user) { create(:user, :locked, password: password, password_confirmation: password) }

      it "returns a failure about locking" do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to include("locked")
      end
    end

    context "when account is inactive" do
      let!(:user) { create(:user, :inactive, password: password, password_confirmation: password) }

      it "returns a failure about account status" do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to include("active")
      end
    end
  end
end
