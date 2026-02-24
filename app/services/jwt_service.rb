# frozen_string_literal: true

# Handles encoding and decoding of JWT tokens.
# Access tokens are short-lived (15 min default).
# Refresh tokens are long-lived (7 days default) and stored in the DB.
module JwtService
  ACCESS_TOKEN_TTL  = ENV.fetch("JWT_ACCESS_TTL_SECONDS",  900).to_i    # 15 min
  REFRESH_TOKEN_TTL = ENV.fetch("JWT_REFRESH_TTL_SECONDS", 604_800).to_i # 7 days
  ALGORITHM = "HS256"

  module_function

  # Encodes a JWT access token for the given user.
  def encode_access(user)
    jti = SecureRandom.uuid
    payload = {
      sub:  user.id,
      jti:  jti,
      role: user.role,
      exp:  ACCESS_TOKEN_TTL.seconds.from_now.to_i,
      iat:  Time.current.to_i,
      iss:  "user_service"
    }
    [JWT.encode(payload, secret, ALGORITHM), jti]
  end

  # Encodes a JWT refresh token.
  def encode_refresh(user)
    payload = {
      sub:  user.id,
      exp:  REFRESH_TOKEN_TTL.seconds.from_now.to_i,
      iat:  Time.current.to_i,
      iss:  "user_service",
      type: "refresh"
    }
    JWT.encode(payload, secret, ALGORITHM)
  end

  # Decodes and verifies a token. Returns the symbolized payload hash or nil.
  def decode(token)
    decoded, = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
    decoded.symbolize_keys
  rescue JWT::DecodeError
    nil
  end

  def secret
    ENV.fetch("JWT_SECRET") { raise "JWT_SECRET environment variable is not set!" }
  end
end
