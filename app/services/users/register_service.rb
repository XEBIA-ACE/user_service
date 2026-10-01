# frozen_string_literal: true

module Users
  # Self-service registration: validates the payload, creates an active
  # account with recorded consent, and starts an authenticated session.
  class RegisterService < BaseService
    MODEL_ERROR_FIELDS = {
      email: :email_address,
      full_name: :full_name,
      first_name: :full_name,
      last_name: :full_name,
      password: :password,
      consent_accepted: :consent_accepted
    }.freeze

    def initialize(params, ip_address: nil, user_agent: nil)
      @form       = RegistrationForm.new(**params.to_h.symbolize_keys.slice(*form_attributes))
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      return failure("Validation failed", errors: @form.errors.to_hash) unless @form.valid?

      user = build_user
      session = nil

      ActiveRecord::Base.transaction do
        return failure("Validation failed", errors: map_model_errors(user.errors)) unless user.save

        session = SessionIssuer.new(user, ip_address: @ip_address, user_agent: @user_agent).call
      end

      Rails.logger.info(event: "user.registered", user_id: user.id)
      success(user: user, session: session)
    end

    private

    def form_attributes
      %i[full_name email_address password consent_accepted]
    end

    def build_user
      first_name, last_name = @form.full_name.split(" ", 2)
      now = Time.current

      User.new(
        full_name: @form.full_name,
        first_name: first_name.to_s.first(100),
        last_name: last_name.to_s.first(100),
        email: @form.email_address,
        username: generate_username,
        password: @form.password,
        consent_accepted: true,
        consent_timestamp: now,
        status: :active
      )
    end

    def generate_username
      base = @form.email_address.split("@").first.to_s.gsub(/[^a-z0-9_.-]/i, "").first(40)
      base = "user" if base.length < 3

      loop do
        candidate = "#{base}-#{SecureRandom.alphanumeric(6).downcase}"
        break candidate unless User.exists?(username: candidate)
      end
    end

    def map_model_errors(errors)
      errors.each_with_object({}) do |error, mapped|
        field = MODEL_ERROR_FIELDS.fetch(error.attribute, :base)
        (mapped[field] ||= []) << error.message
      end
    end
  end
end
