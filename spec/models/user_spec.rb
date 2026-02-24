# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  # ------------------------------------------------------------------
  # Associations
  # ------------------------------------------------------------------
  describe "associations" do
    it { is_expected.to have_many(:user_sessions).dependent(:destroy) }
  end

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }

    it { is_expected.to validate_length_of(:bio).is_at_most(500) }

    context "with invalid email" do
      it "is invalid" do
        user.email = "not-an-email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end
    end

    context "with weak password" do
      it "rejects passwords without special characters" do
        user.password = "password123"
        user.password_confirmation = "password123"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "rejects passwords under 8 characters" do
        user.password = "Abc1!"
        user.password_confirmation = "Abc1!"
        expect(user).not_to be_valid
      end
    end
  end

  # ------------------------------------------------------------------
  # Enums
  # ------------------------------------------------------------------
  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, moderator: 1, admin: 2).with_prefix(:role) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, active: 1, inactive: 2, banned: 3).with_prefix(:status) }
  end

  # ------------------------------------------------------------------
  # Instance methods
  # ------------------------------------------------------------------
  describe "#full_name" do
    it "returns concatenated first and last name" do
      user.first_name = "Jane"
      user.last_name  = "Doe"
      expect(user.full_name).to eq("Jane Doe")
    end
  end

  describe "#locked?" do
    context "when locked_until is in the future" do
      it "returns true" do
        user.locked_until = 1.hour.from_now
        expect(user).to be_locked
      end
    end

    context "when locked_until is nil" do
      it "returns false" do
        user.locked_until = nil
        expect(user).not_to be_locked
      end
    end

    context "when locked_until is in the past" do
      it "returns false" do
        user.locked_until = 1.hour.ago
        expect(user).not_to be_locked
      end
    end
  end

  describe "#record_failed_login!" do
    let!(:user) { create(:user) }

    it "increments failed_login_count" do
      expect { user.record_failed_login! }.to change { user.reload.failed_login_count }.by(1)
    end

    it "locks the account after 3 failures" do
      user.update_columns(failed_login_count: 2)
      user.record_failed_login!
      expect(user.reload.locked_until).to be > Time.current
    end
  end

  describe "#record_login!" do
    let!(:user) { create(:user, :locked) }

    it "resets failed_login_count and clears lock" do
      user.record_login!("127.0.0.1")
      user.reload
      expect(user.failed_login_count).to eq(0)
      expect(user.locked_until).to be_nil
      expect(user.last_login_ip).to eq("127.0.0.1")
    end
  end

  describe "callbacks" do
    it "downcases email before save" do
      user = create(:user, email: "UPPER@EXAMPLE.COM")
      expect(user.reload.email).to eq("upper@example.com")
    end

    it "generates email_verification_token before create" do
      user = create(:user)
      expect(user.email_verification_token).to be_present
    end
  end

  describe "scopes" do
    let!(:active_user)   { create(:user, status: :active) }
    let!(:inactive_user) { create(:user, status: :inactive) }

    describe ".active" do
      it "returns only active users" do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end

    describe ".search_by" do
      it "finds users by email fragment" do
        expect(User.search_by(active_user.email[0..4])).to include(active_user)
      end

      it "returns all records when query is blank" do
        expect(User.search_by("")).to include(active_user, inactive_user)
      end
    end
  end
end
