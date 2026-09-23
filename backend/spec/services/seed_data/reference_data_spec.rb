require "rails_helper"

RSpec.describe SeedData::ReferenceData do
  describe ".apply!" do
    it "upserts countries, departments, and job levels" do
      result = described_class.apply!

      expect(result[:countries].size).to eq(described_class::COUNTRIES.size)
      expect(result[:departments].size).to eq(described_class::DEPARTMENTS.size)
      expect(result[:job_levels].size).to eq(described_class::JOB_LEVELS.size)
      expect(Country.pluck(:code)).to match_array(described_class::COUNTRIES.map { |c| c[:code] })
    end

    it "creates one exchange rate per currency and is safe to re-run" do
      described_class.apply!
      expect { described_class.apply! }.not_to change(Country, :count)
      expect(ExchangeRate.count).to eq(described_class::EXCHANGE_RATES.size)
    end
  end

  describe ".level_bands" do
    it "maps job level rank to its USD salary band" do
      expect(described_class.level_bands[1]).to eq(30_000)
    end
  end
end
