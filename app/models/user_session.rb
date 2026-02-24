# frozen_string_literal: true

class UserSession < ApplicationRecord
  belongs_to :user

  validates :token_jti,     presence: true, uniqueness: true
  validates :refresh_token, presence: true, uniqueness: true
  validates :expires_at,    presence: true

  scope :active,   -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired,  -> { where("expires_at <= ?", Time.current) }
  scope :revoked,  -> { where.not(revoked_at: nil) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
