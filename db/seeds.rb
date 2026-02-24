# frozen_string_literal: true

# This file populates development/staging databases with seed data.
# Run: rails db:seed

puts "Seeding database..."

# Admin user
admin = User.find_or_initialize_by(email: "admin@example.com")
admin.assign_attributes(
  username: "admin",
  first_name: "Admin",
  last_name: "User",
  password: "Admin1234!",
  password_confirmation: "Admin1234!",
  role: :admin,
  status: :active,
  email_verified_at: Time.current
)
admin.save!
puts "  Admin user: #{admin.email}"

# Regular users
10.times do |i|
  email = "user#{i + 1}@example.com"
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    username: "user#{i + 1}",
    first_name: "User",
    last_name: (i + 1).to_s,
    password: "Password1234!",
    password_confirmation: "Password1234!",
    role: :user,
    status: :active,
    email_verified_at: Time.current
  )
  user.save!
  puts "  Regular user: #{user.email}"
end

puts "Done! #{User.count} users total."
