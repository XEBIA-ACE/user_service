# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  set_type :user
  set_id :id

  attributes \
    :email,
    :username,
    :first_name,
    :last_name,
    :phone,
    :avatar_url,
    :bio,
    :role,
    :status,
    :last_login_at,
    :email_verified_at,
    :created_at,
    :updated_at

  attribute :full_name do |user|
    user.full_name
  end

  attribute :locked do |user|
    user.locked?
  end

  attribute :email_verified do |user|
    user.email_verified_at.present?
  end

  # Omit sensitive / internal fields (password_digest, reset tokens, etc.)
end
