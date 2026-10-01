# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Registrations", type: :request do
  let(:headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }
  let(:payload) do
    {
      full_name: "Ada Lovelace",
      email_address: "ada@example.com",
      password: "Str0ng!Pass",
      consent_accepted: true
    }
  end

  def register(body = payload)
    post "/api/v1/users/register", params: body.to_json, headers: headers
  end

  describe "GET /api/v1/users/register" do
    it "returns the form definition and password policy without authentication" do
      get "/api/v1/users/register", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body[:form][:fields].pluck(:name))
        .to eq(%w[full_name email_address password consent_accepted])
      expect(json_body[:password_policy]).to include(
        min_length: 8, max_length: 128, required_classes: %w[lowercase uppercase digit special]
      )
      expect(json_body[:password_policy][:rules]).to all(include(:id, :pattern, :message))
    end
  end

  describe "POST /api/v1/users/register" do
    context "with valid data" do
      it "creates the account and returns 201 with the registration response" do
        expect { register }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_body).to include(
          user_id: kind_of(String),
          account_status: "active",
          created_at: kind_of(String),
          session_token: kind_of(String),
          message: kind_of(String)
        )
        expect(Time.iso8601(json_body[:created_at])).to be_within(1.minute).of(Time.current)
        expect(User.find(json_body[:user_id]).email).to eq("ada@example.com")
      end

      it "does not echo the password" do
        register
        expect(response.body).not_to include(payload[:password])
      end

      it "sets an HttpOnly, Secure, SameSite=Strict session cookie" do
        https!
        register

        set_cookies = Array(response.headers["Set-Cookie"]).join("\n").split("\n")
        cookie = set_cookies.find { |c| c.start_with?("session_token=") }
        expect(cookie).to be_present
        expect(cookie).to include("session_token=#{json_body[:session_token]}")
        expect(cookie).to match(/;\s*httponly/i)
        expect(cookie).to match(/;\s*secure/i)
        expect(cookie).to match(/;\s*samesite=strict/i)
      end

      it "grants access to authenticated features with the bearer session token" do
        register
        token = json_body[:session_token]

        get "/api/v1/users/me", headers: headers.merge("Authorization" => "Bearer #{token}")

        expect(response).to have_http_status(:ok)
        expect(json_data[:attributes][:email]).to eq("ada@example.com")
        expect(json_data[:attributes][:full_name]).to eq("Ada Lovelace")
      end

      it "grants access to authenticated features with the session cookie" do
        register
        cookies["session_token"] = json_body[:session_token]

        get "/api/v1/users/me", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_data[:attributes][:email]).to eq("ada@example.com")
      end

      it "allows the new user to sign in with their credentials" do
        register
        post "/api/v1/auth/login",
             params: { auth: { email: payload[:email_address], password: payload[:password] } }.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context "with missing full name" do
      it "returns 422 with a field-level error" do
        expect { register(payload.except(:full_name)) }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_errors[:details]).to include(full_name: ["can't be blank"])
      end
    end

    context "with an invalid email" do
      it "returns 422 with a field-level error" do
        expect { register(payload.merge(email_address: "not-an-email")) }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_errors[:details]).to include(email_address: ["is not a valid email address"])
      end
    end

    context "with a non-compliant password" do
      it "returns 422 listing each unmet rule" do
        register(payload.merge(password: "password"))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_errors[:details][:password]).to include("must include an uppercase letter")
      end
    end

    context "with consent not accepted" do
      it "returns 422 and does not create an account or set a cookie" do
        expect { register(payload.merge(consent_accepted: false)) }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_errors[:details]).to include(consent_accepted: ["must be accepted"])
        expect(response.headers["Set-Cookie"].to_s).not_to include("session_token=")
      end
    end
  end
end
