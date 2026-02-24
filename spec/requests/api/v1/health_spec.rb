# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /health" do
    it "returns 200 with status ok" do
      get "/health"
      expect(response).to have_http_status(:ok)
      expect(json_body[:status]).to eq("ok")
      expect(json_body[:service]).to eq("user_service")
    end
  end

  describe "GET /readiness" do
    it "returns 200 when DB and Redis are reachable" do
      get "/readiness"
      expect(response).to have_http_status(:ok)
      expect(json_body[:status]).to eq("ok")
      expect(json_body[:checks][:database][:status]).to eq("ok")
      expect(json_body[:checks][:redis][:status]).to eq("ok")
    end
  end

  describe "GET /metrics" do
    before { create_list(:user, 3) }

    it "returns user counts" do
      get "/metrics"
      expect(response).to have_http_status(:ok)
      expect(json_body[:users][:total]).to be >= 3
    end
  end
end
