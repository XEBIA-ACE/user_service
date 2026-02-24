# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid, default: "gen_random_uuid()" do |t|
      # Core identity
      t.string :email,              null: false, limit: 255
      t.string :username,           null: false, limit: 50
      t.string :password_digest,    null: false

      # Profile
      t.string :first_name,         null: false, limit: 100
      t.string :last_name,          null: false, limit: 100
      t.string :phone,              limit: 20
      t.string :avatar_url,         limit: 500
      t.date   :date_of_birth
      t.text   :bio

      # Role & status
      t.integer :role,              null: false, default: 0    # enum: user, moderator, admin
      t.integer :status,            null: false, default: 0    # enum: pending, active, inactive, banned

      # Security / audit
      t.datetime :last_login_at
      t.string   :last_login_ip,    limit: 45
      t.integer  :failed_login_count, null: false, default: 0
      t.datetime :locked_until
      t.string   :password_reset_token, limit: 100
      t.datetime :password_reset_expires_at
      t.datetime :email_verified_at
      t.string   :email_verification_token, limit: 100

      # Metadata
      t.jsonb :metadata,            null: false, default: {}

      t.timestamps
    end

    add_index :users, :email,    unique: true
    add_index :users, :username, unique: true
    add_index :users, :status
    add_index :users, :role
    add_index :users, :created_at
    add_index :users, :metadata, using: :gin
  end
end
