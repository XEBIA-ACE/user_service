# frozen_string_literal: true

module Users
  # Soft-deletes a user by setting status to inactive and anonymising PII,
  # then hard-deletes all active sessions.
  class DeleteService < BaseService
    def initialize(user)
      @user = user
    end

    def call
      ActiveRecord::Base.transaction do
        # Revoke all active sessions
        @user.user_sessions.active.find_each(&:revoke!)

        # Anonymise PII so we can retain audit records without storing personal data
        anonymise_user!
      end

      # Clear cache
      CacheService.delete("user:#{@user.id}")

      Rails.logger.info(event: "user.deleted", user_id: @user.id)
      success
    end

    private

    def anonymise_user!
      anonymised_id = SecureRandom.hex(8)
      @user.update_columns(
        email: "deleted_#{anonymised_id}@deleted.invalid",
        username: "deleted_#{anonymised_id}",
        first_name: "Deleted",
        last_name: "User",
        phone: nil,
        avatar_url: nil,
        bio: nil,
        password_digest: SecureRandom.hex(32), # uncrackable — account is unusable
        status: :inactive,
        updated_at: Time.current
      )
    end
  end
end
