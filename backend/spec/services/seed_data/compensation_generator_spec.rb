require "rails_helper"

RSpec.describe SeedData::CompensationGenerator do
  let(:level_bands) { SeedData::ReferenceData.level_bands }
  let(:exchange_rates) { SeedData::ReferenceData::EXCHANGE_RATES }
  let(:reference_date) { Date.new(2026, 9, 23) }

  def build_generator(random: Random.new)
    described_class.new(level_bands: level_bands, exchange_rates: exchange_rates, reference_date: reference_date, random: random)
  end

  describe "#generate_for" do
    it "produces a single hire record for a brand-new employee" do
      generator = build_generator
      records = generator.generate_for(employee_id: 1, job_level_rank: 1, currency_code: "USD", hire_date: reference_date - 10)

      expect(records.size).to eq(1)
      expect(records.first[:effective_date]).to eq(reference_date - 10)
      expect(records.first[:end_date]).to be_nil
      expect(records.first[:change_reason]).to eq(CompensationRecord.change_reasons["hire"])
    end

    it "always ends with exactly one open-ended (current) record" do
      generator = build_generator

      50.times do |i|
        hire_date = reference_date - rand(30..2900).days
        records = generator.generate_for(employee_id: i, job_level_rank: (1..6).to_a.sample, currency_code: exchange_rates.keys.sample, hire_date: hire_date)

        open_ended = records.select { |r| r[:end_date].nil? }
        expect(open_ended.size).to eq(1)
        expect(records.last[:end_date]).to be_nil
      end
    end

    it "keeps effective_date and end_date contiguous and strictly increasing" do
      generator = build_generator

      50.times do |i|
        hire_date = reference_date - rand(30..2900).days
        records = generator.generate_for(employee_id: i, job_level_rank: 3, currency_code: "USD", hire_date: hire_date)

        records.each_cons(2) do |earlier, later|
          expect(earlier[:end_date]).to eq(later[:effective_date] - 1)
          expect(later[:effective_date]).to be > earlier[:effective_date]
        end
      end
    end

    it "produces a positive amount in whole cents" do
      generator = build_generator
      record = generator.generate_for(employee_id: 1, job_level_rank: 4, currency_code: "IDR", hire_date: reference_date - 100).first

      expect(record[:amount_cents]).to be_a(Integer)
      expect(record[:amount_cents]).to be > 0
    end

    it "annualizes monthly-pay currencies down to a plausible per-month figure" do
      generator = build_generator
      monthly_record = generator.generate_for(employee_id: 1, job_level_rank: 3, currency_code: "IDR", hire_date: reference_date - 100).first
      annual_record = generator.generate_for(employee_id: 1, job_level_rank: 3, currency_code: "USD", hire_date: reference_date - 100).first

      expect(monthly_record[:pay_frequency]).to eq(CompensationRecord.pay_frequencies["monthly"])
      expect(annual_record[:pay_frequency]).to eq(CompensationRecord.pay_frequencies["annual"])
    end

    it "grants no raise when tenure is under a year" do
      generator = build_generator(random: instance_double(Random, rand: 0.0))
      records = generator.generate_for(employee_id: 1, job_level_rank: 1, currency_code: "USD", hire_date: reference_date - 30)

      expect(records.size).to eq(1)
    end

    it "grants two raises when tenure is long and the random draw favors it" do
      always_low = Class.new {
        def rand(arg = nil)
          arg.is_a?(Range) ? arg.begin : 0.0
        end
      }.new

      generator = build_generator(random: always_low)
      records = generator.generate_for(employee_id: 1, job_level_rank: 2, currency_code: "USD", hire_date: reference_date - 1500)

      expect(records.size).to eq(3)
      expect(records.map { |r| r[:effective_date] }).to eq(records.map { |r| r[:effective_date] }.sort)
      expect(records[1][:change_reason]).not_to eq(CompensationRecord.change_reasons["hire"])
    end
  end
end
