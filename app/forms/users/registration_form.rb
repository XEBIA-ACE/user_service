# frozen_string_literal: true

module Users
  # Validates the public self-service registration payload and describes the
  # registration form (fields + password policy) for client rendering.
  class RegistrationForm
    include ActiveModel::Model

    FULL_NAME_MAX_LENGTH = 255
    EMAIL_MAX_LENGTH     = 255

    FIELDS = [
      { name: "full_name", label: "Full name", type: "text", required: true,
        autocomplete: "name", max_length: FULL_NAME_MAX_LENGTH },
      { name: "email_address", label: "Email address", type: "email", required: true,
        autocomplete: "email", max_length: EMAIL_MAX_LENGTH },
      { name: "password", label: "Password", type: "password", required: true,
        autocomplete: "new-password", max_length: PasswordPolicy::MAX_LENGTH },
      { name: "consent_accepted", label: "I agree to the Terms of Service and Privacy Policy",
        type: "checkbox", required: true }
    ].freeze

    attr_reader :full_name, :email_address, :password, :consent_accepted

    validates :full_name, presence: true, length: { maximum: FULL_NAME_MAX_LENGTH }
    validates :email_address, presence: true,
                              length: { maximum: EMAIL_MAX_LENGTH },
                              format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address",
                                        allow_blank: true }
    validates :password, presence: true
    validate  :password_meets_policy
    validate  :consent_must_be_accepted

    def self.schema
      {
        form: {
          action: "/api/v1/users/register",
          method: "POST",
          fields: FIELDS
        },
        password_policy: PasswordPolicy.to_h
      }
    end

    def initialize(full_name: nil, email_address: nil, password: nil, consent_accepted: nil)
      super()
      @full_name        = full_name.to_s.squish
      @email_address    = email_address.to_s.strip.downcase
      @password         = password.to_s
      @consent_accepted = consent_accepted
    end

    def consent_accepted?
      [true, "true"].include?(consent_accepted)
    end

    private

    def password_meets_policy
      return if password.blank?

      PasswordPolicy.violations(password).each { |message| errors.add(:password, message) }
    end

    def consent_must_be_accepted
      errors.add(:consent_accepted, "must be accepted") unless consent_accepted?
    end
  end
end
