# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:regular_user) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin) }
  let(:user_headers)  { auth_headers_for(regular_user) }

  # ------------------------------------------------------------------
  # GET /api/v1/users
  # ------------------------------------------------------------------
  describe "GET /api/v1/users" do
    context "when authenticated as admin" do
      it "returns paginated users" do
        get "/api/v1/users", headers: admin_headers
        expect(response).to have_http_status(:ok)
        expect(json_data).to be_an(Array)
        expect(json_meta).to have_key(:total_count)
      end
    end

    context "when unauthenticated" do
      it "returns 401" do
        get "/api/v1/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with search query" do
      it "filters results by email" do
        get "/api/v1/users", params: { q: admin.email }, headers: admin_headers
        expect(response).to have_http_status(:ok)
        emails = json_data.map { |u| u[:attributes][:email] }
        expect(emails).to include(admin.email)
      end
    end
  end

  # ------------------------------------------------------------------
  # GET /api/v1/users/me
  # ------------------------------------------------------------------
  describe "GET /api/v1/users/me" do
    it "returns the current user" do
      get "/api/v1/users/me", headers: user_headers
      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(regular_user.id)
    end
  end

  # ------------------------------------------------------------------
  # GET /api/v1/users/:id
  # ------------------------------------------------------------------
  describe "GET /api/v1/users/:id" do
    it "returns the user" do
      get "/api/v1/users/#{regular_user.id}", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(regular_user.id)
    end

    it "returns 404 for unknown id" do
      get "/api/v1/users/00000000-0000-0000-0000-000000000000", headers: admin_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  # ------------------------------------------------------------------
  # POST /api/v1/users
  # ------------------------------------------------------------------
  describe "POST /api/v1/users" do
    let(:valid_payload) do
      {
        user: {
          email: "brand_new@example.com",
          username: "brandnew",
          first_name: "Brand",
          last_name: "New",
          password: "Password1234!",
          password_confirmation: "Password1234!"
        }
      }
    end

    context "as admin" do
      it "creates a user and returns 201" do
        post "/api/v1/users", params: valid_payload.to_json, headers: admin_headers
        expect(response).to have_http_status(:created)
        expect(json_data[:attributes][:email]).to eq("brand_new@example.com")
      end

      it "returns 422 on validation error" do
        invalid = valid_payload.deep_merge(user: { email: "not-an-email" })
        post "/api/v1/users", params: invalid.to_json, headers: admin_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as regular user" do
      it "returns 403" do
        post "/api/v1/users", params: valid_payload.to_json, headers: user_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ------------------------------------------------------------------
  # PATCH /api/v1/users/:id
  # ------------------------------------------------------------------
  describe "PATCH /api/v1/users/:id" do
    let(:update_payload) { { user: { first_name: "Updated" } } }

    context "as the user themselves" do
      it "updates the user" do
        patch "/api/v1/users/#{regular_user.id}",
          params: update_payload.to_json,
          headers: user_headers
        expect(response).to have_http_status(:ok)
        expect(json_data[:attributes][:first_name]).to eq("Updated")
      end
    end

    context "as a different regular user" do
      let!(:other_user) { create(:user) }

      it "returns 403" do
        patch "/api/v1/users/#{other_user.id}",
          params: update_payload.to_json,
          headers: user_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ------------------------------------------------------------------
  # DELETE /api/v1/users/:id
  # ------------------------------------------------------------------
  describe "DELETE /api/v1/users/:id" do
    let!(:target) { create(:user) }

    context "as admin" do
      it "returns 204 and anonymises the user" do
        delete "/api/v1/users/#{target.id}", headers: admin_headers
        expect(response).to have_http_status(:no_content)
        expect(target.reload.email).to start_with("deleted_")
      end
    end

    context "as regular user" do
      it "returns 403" do
        delete "/api/v1/users/#{target.id}", headers: user_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
