# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      before_action :set_user, only: %i[show update destroy activate deactivate change_password]
      before_action :authorize_admin!, only: %i[destroy activate deactivate]

      # GET /api/v1/users
      def index
        pagy, users = pagy(
          User.all.search_by(params[:q]).order(sort_column => sort_direction),
          items: per_page
        )

        render_paginated(UserSerializer, users, pagy)
      end

      # GET /api/v1/users/search
      def search
        pagy, users = pagy(
          User.active.search_by(params[:q]).order(:username),
          items: per_page
        )

        render_paginated(UserSerializer, users, pagy)
      end

      # GET /api/v1/users/me
      def me
        render_success UserSerializer.new(current_user).serializable_hash[:data]
      end

      # GET /api/v1/users/:id
      def show
        render_success UserSerializer.new(@user).serializable_hash[:data]
      end

      # POST /api/v1/users
      def create
        authorize_admin!
        result = Users::CreateService.new(user_params).call

        if result.success?
          render_success(
            UserSerializer.new(result.payload).serializable_hash[:data],
            status: :created
          )
        else
          render_validation_error(result.errors)
        end
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        authorize_self_or_admin!(@user)

        result = Users::UpdateService.new(@user, user_params).call

        if result.success?
          render_success UserSerializer.new(result.payload).serializable_hash[:data]
        else
          render_validation_error(result.errors)
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        Users::DeleteService.new(@user).call
        head :no_content
      end

      # PATCH /api/v1/users/:id/activate
      def activate
        @user.update!(status: :active)
        render_success UserSerializer.new(@user).serializable_hash[:data]
      end

      # PATCH /api/v1/users/:id/deactivate
      def deactivate
        @user.update!(status: :inactive)
        render_success UserSerializer.new(@user).serializable_hash[:data]
      end

      # PATCH /api/v1/users/:id/change_password
      def change_password
        authorize_self_or_admin!(@user)

        result = Users::ChangePasswordService.new(
          @user,
          current_password: password_params[:current_password],
          new_password: password_params[:new_password],
          new_password_confirmation: password_params[:new_password_confirmation]
        ).call

        if result.success?
          head :no_content
        else
          render_error :unprocessable_entity, result.error
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :email, :username, :first_name, :last_name,
          :phone, :avatar_url, :date_of_birth, :bio,
          :role, :status, :password, :password_confirmation
        )
      end

      def password_params
        params.require(:user).permit(
          :current_password, :new_password, :new_password_confirmation
        )
      end

      def authorize_admin!
        render_error :forbidden, "Admin access required" unless current_user.role_admin?
      end

      def authorize_self_or_admin!(user)
        return if current_user.role_admin? || current_user.id == user.id

        render_error :forbidden, "You can only modify your own account"
      end

      ALLOWED_SORT_COLUMNS = %w[created_at updated_at email username first_name last_name].freeze

      def sort_column
        ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "created_at"
      end

      def sort_direction
        params[:direction]&.downcase == "asc" ? :asc : :desc
      end

      def per_page
        [[params[:per_page].to_i, 1].max, 100].min.then { |n| n.zero? ? 20 : n }
      end
    end
  end
end
