# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ALLOWED_ORIGINS", "*").split(",").map(&:strip)

    resource "*",
      headers: :any,
      expose: %w[Authorization X-Request-ID X-Total-Count X-Page X-Per-Page],
      methods: %i[get post put patch delete options head],
      max_age: 86_400
  end
end
