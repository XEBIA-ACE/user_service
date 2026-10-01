# frozen_string_literal: true

module Api
  module V1
    # Public, unauthenticated self-service registration.
    class RegistrationsController < ApplicationController
      wrap_parameters false

      # GET /api/v1/users/register
      def new
        render json: Users::RegistrationForm.schema, status: :ok
      end

      # POST /api/v1/users/register
      def create
        result = Users::RegisterService.new(
          registration_params,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ).call

        return render_validation_error(result.errors) if result.failure?

        user    = result.payload[:user]
        session = result.payload[:session]
        write_session_cookie(session)

        render json: {
          message: "Your account has been created and you are now signed in.",
          user_id: user.id,
          full_name: user.full_name,
          email_address: user.email,
          account_status: user.status,
          created_at: user.created_at.iso8601,
          session_token: session[:access_token],
          refresh_token: session[:refresh_token],
          token_type: session[:token_type],
          expires_in: session[:expires_in]
        }, status: :created
      end

      private

      def registration_params
        params.permit(:full_name, :email_address, :password, :consent_accepted)
      end

      def write_session_cookie(session)
        cookies[SESSION_COOKIE_NAME] = {
          value: session[:access_token],
          expires: session[:expires_in].seconds.from_now,
          path: "/",
          httponly: true,
          secure: true,
          same_site: :strict
        }
      end
    end
  end
end
