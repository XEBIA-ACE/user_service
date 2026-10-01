# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "User Service API",
        version: "v1",
        description: <<~DESC
          RESTful API for managing users, authentication, and sessions.
          All protected endpoints require a `Bearer` JWT token in the `Authorization` header.
        DESC
      },
      servers: [
        { url: "http://localhost:3000", description: "Development" },
        { url: "https://api.staging.example.com", description: "Staging" },
        { url: "https://api.example.com", description: "Production" }
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id:               { type: :string, format: :uuid },
              email:            { type: :string, format: :email },
              username:         { type: :string },
              first_name:       { type: :string },
              last_name:        { type: :string },
              full_name:        { type: :string },
              phone:            { type: :string, nullable: true },
              avatar_url:       { type: :string, nullable: true },
              bio:              { type: :string, nullable: true },
              role:             { type: :string, enum: %w[user moderator admin] },
              status:           { type: :string, enum: %w[pending active inactive banned] },
              email_verified:   { type: :boolean },
              locked:           { type: :boolean },
              last_login_at:    { type: :string, format: :"date-time", nullable: true },
              created_at:       { type: :string, format: :"date-time" },
              updated_at:       { type: :string, format: :"date-time" }
            }
          },
          Error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code:    { type: :string },
                  message: { type: :string },
                  details: { type: :object, nullable: true }
                }
              }
            }
          },
          Pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              per_page:     { type: :integer },
              total_count:  { type: :integer },
              total_pages:  { type: :integer }
            }
          }
        }
      },
      security: [{ BearerAuth: [] }]
    }
  }

  config.openapi_format = :yaml
end
