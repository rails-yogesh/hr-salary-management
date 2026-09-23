require "rails_helper"

RSpec.describe Dashboard::Analytics do
  let(:usd) { create(:country, code: "US", currency_code: "USD") }
  let(:idr) { create(:country, code: "ID", currency_code: "IDR") }
  let(:engineering) { create(:department, name: "Engineering") }
  let(:sales) { create(:department, name: "Sales") }
  let(:l1) { create(:job_level, rank: 1) }
  let(:l2) { create(:job_level, rank: 2) }

  before do
    create(:exchange_rate, currency_code: "USD", rate_to_usd: 1.0)
    create(:exchange_rate, currency_code: "IDR", rate_to_usd: 0.0001)
  end

  def employee_with_compensation(country:, department:, job_level:, status: :active, amount_cents:, currency_code:, pay_frequency: :annual)
    employee = create(:employee, country: country, department: department, job_level: job_level, employment_status: status,
      **(status == :terminated ? { termination_date: Date.current } : {}))
    create(:compensation_record, employee: employee, amount_cents: amount_cents, currency_code: currency_code, pay_frequency: pay_frequency)
    employee
  end

  describe ".summary" do
    it "sums annualized, USD-converted cost across currencies and pay frequencies" do
      # $100,000/yr in the US -> $100,000 USD
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 100_000_00, currency_code: "USD", pay_frequency: :annual)
      # 50,000,000 IDR/month -> 600,000,000 IDR/yr -> * 0.0001 = 60,000 USD
      employee_with_compensation(country: idr, department: engineering, job_level: l1, amount_cents: 50_000_000_00, currency_code: "IDR", pay_frequency: :monthly)

      result = described_class.summary

      expect(result[:headcount]).to eq(2)
      expect(result[:total_annual_cost_usd_cents]).to eq(100_000_00 + 60_000_00)
      expect(result[:average_annual_cost_usd_cents]).to eq((100_000_00 + 60_000_00) / 2)
    end

    it "excludes terminated employees but includes active and on_leave" do
      employee_with_compensation(country: usd, department: engineering, job_level: l1, status: :active, amount_cents: 100_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: engineering, job_level: l1, status: :on_leave, amount_cents: 100_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: engineering, job_level: l1, status: :terminated, amount_cents: 999_999_00, currency_code: "USD")

      expect(described_class.summary[:headcount]).to eq(2)
    end

    it "returns zero, not an error, with no employees" do
      expect(described_class.summary).to eq(headcount: 0, total_annual_cost_usd_cents: 0, average_annual_cost_usd_cents: 0)
    end
  end

  describe ".by_country" do
    it "groups headcount and cost by country" do
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 100_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 50_000_00, currency_code: "USD")
      employee_with_compensation(country: idr, department: engineering, job_level: l1, amount_cents: 600_000_000_00, currency_code: "IDR")

      result = described_class.by_country.index_by { |r| r[:label] }

      expect(result[usd.name][:headcount]).to eq(2)
      expect(result[usd.name][:total_annual_cost_usd_cents]).to eq(150_000_00)
      expect(result[idr.name][:headcount]).to eq(1)
      expect(result[idr.name][:total_annual_cost_usd_cents]).to eq(60_000_00)
    end
  end

  describe ".by_department" do
    it "groups headcount and cost by department" do
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 100_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: sales, job_level: l1, amount_cents: 80_000_00, currency_code: "USD")

      result = described_class.by_department.index_by { |r| r[:label] }

      expect(result[engineering.name][:total_annual_cost_usd_cents]).to eq(100_000_00)
      expect(result[sales.name][:total_annual_cost_usd_cents]).to eq(80_000_00)
    end
  end

  describe ".salary_distribution" do
    it "groups by job level, ordered by rank, with min/max/average" do
      employee_with_compensation(country: usd, department: engineering, job_level: l2, amount_cents: 200_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 50_000_00, currency_code: "USD")
      employee_with_compensation(country: usd, department: engineering, job_level: l1, amount_cents: 70_000_00, currency_code: "USD")

      result = described_class.salary_distribution

      expect(result.map { |r| r[:label] }).to eq([ l1.name, l2.name ])
      l1_row = result.first
      expect(l1_row[:headcount]).to eq(2)
      expect(l1_row[:min_annual_cost_usd_cents]).to eq(50_000_00)
      expect(l1_row[:max_annual_cost_usd_cents]).to eq(70_000_00)
      expect(l1_row[:average_annual_cost_usd_cents]).to eq(60_000_00)
    end
  end
end
