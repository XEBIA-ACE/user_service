# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Pagy::Backend

  SESSION_COOKIE_NAME = "session_token"

  # ------------------------------------------------------------------
  # Error handling
  # ------------------------------------------------------------------
  rescue_from ActiveRecord::RecordNotFound,       with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid,        with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from Pagy::OverflowError,                with: :page_overflow

  # ------------------------------------------------------------------
  # Logging helpers — appended to lograge custom_options
  # ------------------------------------------------------------------
  def append_info_to_payload(payload)
    super
    payload[:request_id]      = request.request_id
    payload[:ip]              = request.remote_ip
    payload[:current_user_id] = current_user&.id
  end

  private

  # ------------------------------------------------------------------
  # Authentication helpers
  # ------------------------------------------------------------------

  def authenticate_user!
    token = extract_bearer_token
    raise Errors::Unauthorized, "Missing authentication token" if token.blank?

    decoded = JwtService.decode(token)
    raise Errors::Unauthorized, "Invalid or expired token" unless decoded

    # Check token is not revoked in Redis
    raise Errors::Unauthorized, "Token has been revoked" if token_revoked?(decoded[:jti])

    @current_user = User.active.find_by(id: decoded[:sub])
    raise Errors::Unauthorized, "User not found or inactive" unless @current_user
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    render_error :unauthorized, e.message
  rescue Errors::Unauthorized => e
    render_error :unauthorized, e.message
  end

  def authenticate_admin!
    authenticate_user!
    render_error :forbidden, "Admin access required" unless current_user&.role_admin?
  end

  def current_user
    @current_user
  end

  # ------------------------------------------------------------------
  # Response helpers
  # ------------------------------------------------------------------

  def render_success(data, status: :ok, meta: {})
    response_body = { data: data }
    response_body[:meta] = meta if meta.present?
    render json: response_body, status: status
  end

  def render_paginated(serializer_class, records, pagy)
    data = serializer_class.new(records).serializable_hash[:data]
    render json: {
      data: data,
      meta: {
        current_page: pagy.page,
        per_page: pagy.items,
        total_count: pagy.count,
        total_pages: pagy.pages
      }
    }, status: :ok
  end

  def render_error(status, message, details: nil)
    body = { error: { code: status.to_s, message: message } }
    body[:error][:details] = details if details.present?
    render json: body, status: status
  end

  def render_validation_error(record_or_errors)
    errors = case record_or_errors
             when ActiveRecord::Base then record_or_errors.errors
             when Hash then record_or_errors
             else record_or_errors
             end
    render_error :unprocessable_entity, "Validation failed", details: errors
  end

  # ------------------------------------------------------------------
  # Private helpers
  # ------------------------------------------------------------------

  def extract_bearer_token
    request.headers["Authorization"]&.sub(/\ABearer /, "").presence || cookies[SESSION_COOKIE_NAME]
  end

  def token_revoked?(jti)
    RedisPool.with { |conn| conn.get("revoked_token:#{jti}") }.present?
  end

  # ------------------------------------------------------------------
  # Error handlers
  # ------------------------------------------------------------------

  def record_not_found(exception)
    render_error :not_found, exception.message
  end

  def record_invalid(exception)
    render_validation_error(exception.record.errors.full_messages)
  end

  def parameter_missing(exception)
    render_error :bad_request, exception.message
  end

  def page_overflow(_exception)
    render_error :unprocessable_entity, "Page number is out of range"
  end
end
