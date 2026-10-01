# frozen_string_literal: true

module Users
  # Issues a JWT access/refresh token pair for a user and persists the
  # corresponding UserSession record used for auditing and revocation.
  class SessionIssuer
    def initialize(user, ip_address: nil, user_agent: nil)
      @user       = user
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      access_token, jti = JwtService.encode_access(@user)
      refresh_token = JwtService.encode_refresh(@user)

      @user.user_sessions.create!(
        token_jti: jti,
        refresh_token: SecureRandom.hex(32), # opaque token stored in DB
        ip_address: @ip_address,
        user_agent: @user_agent,
        expires_at: JwtService::ACCESS_TOKEN_TTL.seconds.from_now
      )

      {
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: "Bearer",
        expires_in: JwtService::ACCESS_TOKEN_TTL
      }
    end
  end
end
