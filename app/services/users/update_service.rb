# frozen_string_literal: true

module Users
  # Updates an existing user record.
  # Invalidates the user's cache entry on success.
  class UpdateService < BaseService
    def initialize(user, params)
      @user   = user
      @params = params.to_h.with_indifferent_access
    end

    def call
      if @user.update(permitted_params)
        CacheService.delete("user:#{@user.id}")

        Rails.logger.info(
          event: "user.updated",
          user_id: @user.id,
          changed: @user.previous_changes.keys
        )

        success(@user)
      else
        failure("Validation failed", errors: @user.errors.as_json)
      end
    end

    private

    def permitted_params
      @params.slice(
        :email, :username, :first_name, :last_name,
        :phone, :avatar_url, :date_of_birth, :bio
      )
    end
  end
end
