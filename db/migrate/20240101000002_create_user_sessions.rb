# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token_jti,   null: false, limit: 100   # JWT ID for revocation
      t.string :refresh_token, null: false, limit: 100
      t.string :ip_address,  limit: 45
      t.string :user_agent,  limit: 500
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :user_sessions, :token_jti,     unique: true
    add_index :user_sessions, :refresh_token, unique: true
    add_index :user_sessions, :expires_at
  end
end
