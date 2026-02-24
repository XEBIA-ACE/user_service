# frozen_string_literal: true

module Users
  # Changes a user's password after verifying the current password.
  # Revokes all existing sessions so other devices are signed out.
  class ChangePasswordService < BaseService
    def initialize(user, current_password:, new_password:, new_password_confirmation:)
      @user                     = user
      @current_password         = current_password.to_s
      @new_password             = new_password.to_s
      @new_password_confirmation = new_password_confirmation.to_s
    end

    def call
      return failure("Current password is incorrect") unless @user.authenticate(@current_password)
      return failure("New password must differ from the current password") if @current_password == @new_password
      return failure("Password confirmation does not match") if @new_password != @new_password_confirmation

      ActiveRecord::Base.transaction do
        @user.update!(
          password: @new_password,
          password_confirmation: @new_password_confirmation
        )

        # Revoke all sessions — force re-login on all devices
        @user.user_sessions.active.find_each(&:revoke!)
      end

      Rails.logger.info(event: "user.password_changed", user_id: @user.id)
      success
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
