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
end
