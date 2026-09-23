require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  subject { build(:exchange_rate) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:as_of_date) }
  it { is_expected.to validate_uniqueness_of(:currency_code).ignoring_case_sensitivity }

  it "rejects a non-positive rate" do
    rate = build(:exchange_rate, rate_to_usd: 0)

    expect(rate).not_to be_valid
    expect(rate.errors[:rate_to_usd]).to be_present
  end

  describe ".usd_cents_for" do
    it "returns the amount unchanged for USD" do
      expect(ExchangeRate.usd_cents_for(amount_cents: 5_000, currency_code: "USD")).to eq(5_000)
    end

    it "converts using the stored rate" do
      create(:exchange_rate, currency_code: "IDR", rate_to_usd: 0.000065)

      expect(ExchangeRate.usd_cents_for(amount_cents: 100_000_000, currency_code: "IDR")).to eq(6_500)
    end

    it "raises when no rate is configured" do
      expect {
        ExchangeRate.usd_cents_for(amount_cents: 100, currency_code: "ZZZ")
      }.to raise_error(ArgumentError, /no exchange rate for ZZZ/)
    end
  end
end
