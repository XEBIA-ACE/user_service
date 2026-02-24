# frozen_string_literal: true

module Users
  # Validates a refresh token and issues a new access token.
  # Implements refresh-token rotation to mitigate token theft.
  class RefreshTokenService < BaseService
    def initialize(refresh_token:)
      @refresh_token = refresh_token.to_s
    end

    def call
      decoded = JwtService.decode(@refresh_token)
      return failure("Invalid or expired refresh token") unless decoded
      return failure("Not a refresh token") unless decoded[:type] == "refresh"

      user = User.active.find_by(id: decoded[:sub])
      return failure("User not found or inactive") unless user

      # Issue new tokens (rotation)
      access_token, jti = JwtService.encode_access(user)
      new_refresh_token  = JwtService.encode_refresh(user)

      # Create new session record
      user.user_sessions.create!(
        token_jti: jti,
        refresh_token: SecureRandom.hex(32),
        expires_at: JwtService::ACCESS_TOKEN_TTL.seconds.from_now
      )

      Rails.logger.info(event: "user.token_refreshed", user_id: user.id)

      success({
        access_token: access_token,
        refresh_token: new_refresh_token,
        token_type: "Bearer",
        expires_in: JwtService::ACCESS_TOKEN_TTL
      })
    end
  end
end
