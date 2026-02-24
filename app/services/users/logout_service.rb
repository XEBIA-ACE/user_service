# frozen_string_literal: true

module Users
  # Revokes the current access token by adding its JTI to a Redis denylist,
  # and marks the corresponding session as revoked in the database.
  class LogoutService < BaseService
    def initialize(token:, user:)
      @token = token
      @user  = user
    end

    def call
      decoded = JwtService.decode(@token)
      return success unless decoded  # token already invalid — nothing to do

      jti        = decoded[:jti]
      expires_at = Time.at(decoded[:exp])
      ttl        = [(expires_at - Time.current).to_i, 0].max

      # Add JTI to denylist for its remaining lifetime
      if jti.present? && ttl.positive?
        RedisClient.with { |conn| conn.setex("revoked_token:#{jti}", ttl, "1") }
      end

      # Revoke the DB session record if present
      session = @user.user_sessions.find_by(token_jti: jti)
      session&.revoke!

      Rails.logger.info(event: "user.logout", user_id: @user.id, jti: jti)
      success
    end
  end
end
