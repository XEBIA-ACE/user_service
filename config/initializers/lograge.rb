# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.base_controller_class = "ActionController::API"

  # Emit structured JSON logs
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Include extra fields in every log line
  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:request_id],
      user_id: event.payload[:current_user_id],
      ip: event.payload[:ip],
      params: event.payload[:params]
        &.except("controller", "action", "format", "authenticity_token")
        &.to_h
    }.compact
  end
end
