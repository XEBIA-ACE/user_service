# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    password   { "Password1234!" }
    password_confirmation { "Password1234!" }
    role   { :user }
    status { :active }
    email_verified_at { Time.current }

    trait :admin do
      role { :admin }
      sequence(:email) { |n| "admin#{n}@example.com" }
      sequence(:username) { |n| "admin#{n}" }
    end

    trait :moderator do
      role { :moderator }
    end

    trait :pending do
      status { :pending }
      email_verified_at { nil }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :banned do
      status { :banned }
    end

    trait :locked do
      locked_until { 1.hour.from_now }
      failed_login_count { 5 }
    end
  end
end
