# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: %i[logout]

      # POST /api/v1/auth/login
      def login
        result = Users::AuthService.new(
          email: login_params[:email],
          password: login_params[:password],
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ).call

        if result.success?
          render json: result.payload, status: :ok
        else
          render_error :unauthorized, result.error
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        result = Users::RefreshTokenService.new(
          refresh_token: params.require(:refresh_token)
        ).call

        if result.success?
          render json: result.payload, status: :ok
        else
          render_error :unauthorized, result.error
        end
      end

      # DELETE /api/v1/auth/logout
      def logout
        token = extract_bearer_token
        Users::LogoutService.new(token: token, user: current_user).call
        head :no_content
      end

      private

      def login_params
        params.require(:auth).permit(:email, :password)
      end
    end
  end
end
