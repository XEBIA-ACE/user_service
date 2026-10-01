# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::RegisterService do
  let(:params) do
    {
      full_name: "Ada Lovelace",
      email_address: "ada@example.com",
      password: "Str0ng!Pass",
      consent_accepted: true
    }
  end

  subject(:result) { described_class.new(params, ip_address: "127.0.0.1", user_agent: "RSpec").call }

  context "with valid data" do
    it "persists an active account with recorded consent" do
      expect { result }.to change(User, :count).by(1)

      user = result.payload[:user]
      expect(user).to be_persisted
      expect(user).to be_status_active
      expect(user.full_name).to eq("Ada Lovelace")
      expect(user.first_name).to eq("Ada")
      expect(user.last_name).to eq("Lovelace")
      expect(user.email).to eq("ada@example.com")
      expect(user.consent_accepted).to be(true)
      expect(user.consent_timestamp).to be_within(5.seconds).of(Time.current)
    end

    it "never stores the plaintext password" do
      user = result.payload[:user].reload
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to include(params[:password])
      expect(user.authenticate(params[:password])).to eq(user)
    end

    it "generates a valid unique username" do
      expect(result.payload[:user].username).to match(/\Aada-[a-z0-9]{6}\z/)
    end

    it "issues a session token and stores the session" do
      expect { result }.to change(UserSession, :count).by(1)

      session = result.payload[:session]
      decoded = JwtService.decode(session[:access_token])
      user_session = UserSession.last

      expect(decoded[:sub]).to eq(result.payload[:user].id)
      expect(user_session.token_jti).to eq(decoded[:jti])
      expect(user_session.user).to eq(result.payload[:user])
      expect(user_session).to be_active
      expect(session).to include(token_type: "Bearer", expires_in: JwtService::ACCESS_TOKEN_TTL)
    end

    it "supports single-word names" do
      params[:full_name] = "Prince"
      user = result.payload[:user]
      expect(result).to be_success
      expect(user.full_name).to eq("Prince")
      expect(user.last_name).to eq("")
    end
  end

  context "when consent is not accepted" do
    before { params[:consent_accepted] = false }

    it "is rejected before any database write" do
      expect { result }.not_to change(User, :count)
      expect(UserSession.count).to eq(0)
      expect(result).to be_failure
      expect(result.errors).to include(consent_accepted: ["must be accepted"])
    end
  end

  context "when the email is already registered" do
    before { create(:user, email: "ada@example.com") }

    it "maps the model error to email_address" do
      expect { result }.not_to change(User, :count)
      expect(result.errors).to include(email_address: ["has already been taken"])
    end
  end
end
