# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_10_01_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "user_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token_jti", limit: 100, null: false
    t.string "refresh_token", limit: 100, null: false
    t.string "ip_address", limit: 45
    t.string "user_agent", limit: 500
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["refresh_token"], name: "index_user_sessions_on_refresh_token", unique: true
    t.index ["token_jti"], name: "index_user_sessions_on_token_jti", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "username", limit: 50, null: false
    t.string "password_digest", null: false
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "phone", limit: 20
    t.string "avatar_url", limit: 500
    t.date "date_of_birth"
    t.text "bio"
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "last_login_at"
    t.string "last_login_ip", limit: 45
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "locked_until"
    t.string "password_reset_token", limit: 100
    t.datetime "password_reset_expires_at"
    t.datetime "email_verified_at"
    t.string "email_verification_token", limit: 100
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name", limit: 255
    t.boolean "consent_accepted", default: false, null: false
    t.datetime "consent_timestamp"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["metadata"], name: "index_users_on_metadata", using: :gin
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "user_sessions", "users"
end
