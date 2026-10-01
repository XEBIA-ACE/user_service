# frozen_string_literal: true

Rails.application.routes.draw do
  # Health & metrics endpoints
  get "/health", to: "api/v1/health#show"
  get "/metrics", to: "api/v1/health#metrics"
  get "/readiness", to: "api/v1/health#readiness"

  # Swagger API docs
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # Versioned API
  namespace :api do
    namespace :v1 do
      # Authentication
      post "/auth/login", to: "auth#login"
      post "/auth/refresh", to: "auth#refresh"
      delete "/auth/logout", to: "auth#logout"

      # Self-service registration (declared before the users resource so
      # "register" is not captured as a user :id)
      get  "/users/register", to: "registrations#new",    as: :new_registration
      post "/users/register", to: "registrations#create", as: :registration

      # Users resource
      resources :users, only: %i[index show create update destroy] do
        collection do
          get :search
          get :me
        end
        member do
          patch :activate
          patch :deactivate
          patch :change_password
        end
      end
    end
  end
end
