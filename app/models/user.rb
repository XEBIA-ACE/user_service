# frozen_string_literal: true

class User < ApplicationRecord
  include BCrypt

  # ------------------------------------------------------------------
  # Enums
  # ------------------------------------------------------------------
  enum :role,   { user: 0, moderator: 1, admin: 2 }, prefix: true
  enum :status, { pending: 0, active: 1, inactive: 2, banned: 3 }, prefix: true

  # ------------------------------------------------------------------
  # Associations
  # ------------------------------------------------------------------
  has_many :user_sessions, dependent: :destroy

  # ------------------------------------------------------------------
  # Callbacks
  # ------------------------------------------------------------------
  before_save :downcase_email
  before_create :generate_email_verification_token

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP },
    length: { maximum: 255 }

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9_.-]+\z/i, message: "only allows letters, numbers, underscores, dots and dashes" },
    length: { minimum: 3, maximum: 50 }

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name,  presence: true, length: { maximum: 100 }
  validates :phone,      format: { with: /\A\+?[0-9\s\-().]{7,20}\z/ }, allow_blank: true
  validates :bio,        length: { maximum: 500 }, allow_blank: true

  # Password validation is handled by has_secure_password
  has_secure_password
  validates :password, length: { minimum: 8, maximum: 128 },
                       format: {
                         with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+\z/,
                         message: "must include uppercase, lowercase, digit and special character"
                       },
                       if: :password_required?

  # ------------------------------------------------------------------
  # Scopes
  # ------------------------------------------------------------------
  scope :active,    -> { where(status: :active) }
  scope :search_by, ->(query) {
    return all if query.blank?

    where(
      "email ILIKE :q OR username ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q",
      q: "%#{sanitize_sql_like(query)}%"
    )
  }

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------

  # Returns full display name.
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Checks whether the account is currently locked due to failed logins.
  def locked?
    locked_until.present? && locked_until > Time.current
  end

  # Records a successful login.
  def record_login!(ip_address)
    update_columns(
      last_login_at: Time.current,
      last_login_ip: ip_address,
      failed_login_count: 0,
      locked_until: nil
    )
  end

  # Increments failed login counter and locks account after threshold.
  def record_failed_login!
    count = failed_login_count + 1
    attrs = { failed_login_count: count }

    # Lock for exponential backoff: 1 min, 5 min, 15 min, 1 hr, 24 hr
    thresholds = { 3 => 1.minute, 5 => 5.minutes, 7 => 15.minutes, 9 => 1.hour, 10 => 24.hours }
    if (duration = thresholds[count])
      attrs[:locked_until] = duration.from_now
    end

    update_columns(attrs)
  end

  # Generates and persists a password-reset token.
  def generate_password_reset_token!
    token = SecureRandom.urlsafe_base64(32)
    update_columns(
      password_reset_token: token,
      password_reset_expires_at: 1.hour.from_now
    )
    token
  end

  # Clears the password-reset token after use.
  def clear_password_reset_token!
    update_columns(password_reset_token: nil, password_reset_expires_at: nil)
  end

  # Marks the email address as verified.
  def verify_email!
    update_columns(
      email_verified_at: Time.current,
      email_verification_token: nil,
      status: :active
    )
  end

  # ------------------------------------------------------------------
  private
  # ------------------------------------------------------------------

  def downcase_email
    self.email = email.downcase
  end

  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
  end

  # Only validate password when it is being set (creation or explicit update).
  def password_required?
    new_record? || password.present?
  end
end
