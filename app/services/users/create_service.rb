# frozen_string_literal: true

module Users
  # Creates a new user record after validating input.
  # Returns ServiceResult with the created User on success.
  class CreateService < BaseService
    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def call
      user = User.new(permitted_params)
      user.status = :pending  # new users start pending until email verified

      if user.save
        Rails.logger.info(
          event: "user.created",
          user_id: user.id,
          email: user.email
        )
        success(user)
      else
        failure("Validation failed", errors: user.errors.as_json)
      end
    end

    private

    def permitted_params
      @params.slice(
        :email, :username, :first_name, :last_name,
        :phone, :avatar_url, :date_of_birth, :bio,
        :password, :password_confirmation, :role
      )
    end
  end
end
