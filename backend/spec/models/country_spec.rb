require "rails_helper"

RSpec.describe Country, type: :model do
  subject { build(:country) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:currency_code) }
  it { is_expected.to validate_uniqueness_of(:code).ignoring_case_sensitivity }
  it { is_expected.to have_many(:employees) }

  it "upcases code and currency_code before validation" do
    country = build(:country, code: "id", currency_code: "idr")

    country.valid?

    expect(country.code).to eq("ID")
    expect(country.currency_code).to eq("IDR")
  end

  it "rejects a code that is not exactly 2 characters" do
    country = build(:country, code: "IDN")

    expect(country).not_to be_valid
    expect(country.errors[:code]).to be_present
  end
end
