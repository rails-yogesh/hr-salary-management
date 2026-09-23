require "rails_helper"

RSpec.describe CompensationRecord, type: :model do
  subject { build(:compensation_record) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:employee) }

  it "joins to its exchange rate by currency code" do
    rate = create(:exchange_rate, currency_code: "EUR")
    record = create(:compensation_record, currency_code: "EUR")

    expect(record.exchange_rate).to eq(rate)
  end
  it { is_expected.to validate_presence_of(:currency_code) }
  it { is_expected.to validate_presence_of(:effective_date) }
  it { is_expected.to define_enum_for(:pay_frequency).with_values(monthly: 0, annual: 1) }
  it {
    is_expected.to define_enum_for(:change_reason)
      .with_values(hire: 0, promotion: 1, annual_review: 2, market_adjustment: 3, correction: 4)
  }

  describe "amount_cents" do
    it "must be greater than zero" do
      record = build(:compensation_record, amount_cents: 0)

      expect(record).not_to be_valid
      expect(record.errors[:amount_cents]).to be_present
    end
  end

  describe "currency_code" do
    it "is upcased before validation" do
      record = build(:compensation_record, currency_code: "usd")

      record.valid?

      expect(record.currency_code).to eq("USD")
    end
  end

  describe "end_date" do
    it "cannot be before effective_date" do
      record = build(:compensation_record, effective_date: Date.new(2026, 1, 1), end_date: Date.new(2025, 12, 31))

      expect(record).not_to be_valid
      expect(record.errors[:end_date]).to include("can't be before effective date")
    end
  end

  describe "the append-only current-record invariant" do
    it "rejects a second current record for the same employee" do
      employee = create(:employee)
      create(:compensation_record, employee: employee, end_date: nil)

      second = build(:compensation_record, employee: employee, end_date: nil)

      expect(second).not_to be_valid
      expect(second.errors[:base]).to include("employee already has a current compensation record")
    end

    it "allows a new current record once the prior one has an end_date" do
      employee = create(:employee)
      create(:compensation_record, employee: employee, end_date: Date.yesterday)

      second = build(:compensation_record, employee: employee, end_date: nil)

      expect(second).to be_valid
    end

    it "is enforced at the database level too" do
      employee = create(:employee)
      create(:compensation_record, employee: employee, end_date: nil)

      expect {
        CompensationRecord.insert!({
          employee_id: employee.id,
          amount_cents: 100,
          currency_code: "USD",
          pay_frequency: 1,
          change_reason: 0,
          effective_date: Date.current,
          end_date: nil,
          created_at: Time.current,
          updated_at: Time.current
        })
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#annual_amount_cents" do
    it "multiplies monthly pay by 12" do
      record = build(:compensation_record, pay_frequency: :monthly, amount_cents: 1_000_00)

      expect(record.annual_amount_cents).to eq(12_000_00)
    end

    it "returns annual pay as-is" do
      record = build(:compensation_record, pay_frequency: :annual, amount_cents: 120_000_00)

      expect(record.annual_amount_cents).to eq(120_000_00)
    end
  end

  describe "scopes" do
    it ".current returns only open-ended records" do
      employee = create(:employee)
      current = create(:compensation_record, employee: employee, end_date: nil)
      create(:compensation_record, employee: create(:employee), end_date: Date.yesterday)

      expect(CompensationRecord.current).to contain_exactly(current)
    end
  end
end
