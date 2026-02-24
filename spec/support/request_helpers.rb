# frozen_string_literal: true

module RequestHelpers
  # Generates a valid Authorization header for the given user.
  def auth_headers_for(user)
    access_token, = JwtService.encode_access(user)
    { "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json" }
  end

  def json_body
    JSON.parse(response.body, symbolize_names: true)
  end

  def json_data
    json_body[:data]
  end

  def json_errors
    json_body[:error]
  end

  def json_meta
    json_body[:meta]
  end
end
