# frozen_string_literal: true

module Users
  # Authenticates a user with email + password and issues JWT tokens.
  # Handles account locking and records login metadata.
  class AuthService < BaseService
    def initialize(email:, password:, ip_address: nil, user_agent: nil)
      @email      = email.to_s.downcase.strip
      @password   = password.to_s
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      user = User.find_by(email: @email)

      return failure("Invalid email or password") unless user
      return failure("Account is locked. Try again later.") if user.locked?
      return failure("Account is not active.") unless user.status_active?

      unless user.authenticate(@password)
        user.record_failed_login!
        return failure("Invalid email or password")
      end

      tokens = issue_tokens!(user)
      user.record_login!(@ip_address)

      Rails.logger.info(event: "user.login", user_id: user.id, ip: @ip_address)
      success(tokens)
    end

    private

    def issue_tokens!(user)
      tokens = SessionIssuer.new(user, ip_address: @ip_address, user_agent: @user_agent).call

      tokens.merge(
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        }
      )
    end
  end
end
