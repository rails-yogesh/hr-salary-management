require "rails_helper"

RSpec.describe AdminUser, type: :model do
  subject { build(:admin_user) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_secure_password }

  it "downcases email before validation" do
    user = build(:admin_user, email: "HR@ACME.test")

    user.valid?

    expect(user.email).to eq("hr@acme.test")
  end

  it "rejects a duplicate email regardless of case" do
    create(:admin_user, email: "hr@acme.test")
    duplicate = build(:admin_user, email: "HR@acme.test")

    expect(duplicate).not_to be_valid
  end

  it "authenticates only with the correct password" do
    user = create(:admin_user, password: "correct-horse-battery-staple")

    expect(user.authenticate("correct-horse-battery-staple")).to eq(user)
    expect(user.authenticate("wrong-password")).to be false
  end

  describe "password length (security review 2026-09-23, SEC-M2)" do
    it "rejects a password shorter than 12 characters" do
      user = build(:admin_user, password: "short1!")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "accepts a password of exactly 12 characters" do
      user = build(:admin_user, password: "exactly12chr")

      expect(user).to be_valid
    end

    it "does not require a password on updates that don't touch it" do
      user = create(:admin_user)

      user.email = "new-email@acme.test"

      expect(user).to be_valid
    end
  end
end
