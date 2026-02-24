# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Users API", type: :request do
  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :q,          in: :query, type: :string,  required: false, description: "Search query"
      parameter name: :page,       in: :query, type: :integer, required: false
      parameter name: :per_page,   in: :query, type: :integer, required: false
      parameter name: :sort,       in: :query, type: :string,  required: false
      parameter name: :direction,  in: :query, type: :string,  required: false, enum: %w[asc desc]

      response "200", "Users listed" do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { "$ref" => "#/components/schemas/User" } },
                 meta: { "$ref" => "#/components/schemas/Pagination" }
               }
        run_test!
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end

    post "Create user" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            required: %w[email username first_name last_name password password_confirmation],
            properties: {
              email:                 { type: :string },
              username:              { type: :string },
              first_name:            { type: :string },
              last_name:             { type: :string },
              password:              { type: :string },
              password_confirmation: { type: :string }
            }
          }
        }
      }

      response "201", "User created" do
        schema type: :object, properties: { data: { "$ref" => "#/components/schemas/User" } }
        run_test!
      end

      response "422", "Validation failed" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end

      response "403", "Forbidden" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :string, format: :uuid

    get "Get user" do
      tags "Users"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response "200", "User found" do
        schema type: :object, properties: { data: { "$ref" => "#/components/schemas/User" } }
        run_test!
      end

      response "404", "Not found" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end

    patch "Update user" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name:  { type: :string },
              phone:      { type: :string },
              bio:        { type: :string }
            }
          }
        }
      }

      response "200", "User updated" do
        schema type: :object, properties: { data: { "$ref" => "#/components/schemas/User" } }
        run_test!
      end
    end

    delete "Delete user" do
      tags "Users"
      security [{ BearerAuth: [] }]

      response "204", "User deleted" do
        run_test!
      end

      response "403", "Forbidden" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/users/me" do
    get "Get current user" do
      tags "Users"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response "200", "Current user" do
        schema type: :object, properties: { data: { "$ref" => "#/components/schemas/User" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Login" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :body, in: :body, schema: {
        type: :object,
        required: %w[auth],
        properties: {
          auth: {
            type: :object,
            required: %w[email password],
            properties: {
              email:    { type: :string },
              password: { type: :string }
            }
          }
        }
      }

      response "200", "Authenticated" do
        schema type: :object,
               properties: {
                 access_token:  { type: :string },
                 refresh_token: { type: :string },
                 token_type:    { type: :string },
                 expires_in:    { type: :integer }
               }
        run_test!
      end

      response "401", "Invalid credentials" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
