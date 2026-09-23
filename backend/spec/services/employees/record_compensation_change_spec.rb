require "rails_helper"

RSpec.describe Employees::RecordCompensationChange do
  let(:employee) { create(:employee) }

  describe "when the employee has a current record" do
    let!(:original) { create(:compensation_record, employee: employee, effective_date: Date.new(2025, 1, 1), amount_cents: 100_000_00) }

    it "closes the original record and opens a new current one" do
      result = described_class.new(
        employee: employee,
        attributes: {
          amount_cents: 120_000_00, currency_code: "USD", pay_frequency: :annual,
          effective_date: Date.new(2026, 1, 1), change_reason: :promotion
        }
      ).call

      expect(result).to be_success
      original.reload
      expect(original.end_date).to eq(Date.new(2025, 12, 31))

      current = employee.reload.current_compensation_record
      expect(current.id).to eq(result.compensation_record.id)
      expect(current.amount_cents).to eq(120_000_00)
      expect(current).to be_promotion
    end

    it "rejects an effective_date that doesn't come after the current record's" do
      result = described_class.new(
        employee: employee,
        attributes: {
          amount_cents: 120_000_00, currency_code: "USD", pay_frequency: :annual,
          effective_date: Date.new(2025, 1, 1), change_reason: :promotion
        }
      ).call

      expect(result).not_to be_success
      expect(result.errors.join).to match(/effective_date must be after/)
      expect(original.reload.end_date).to be_nil
      expect(employee.compensation_records.count).to eq(1)
    end

    it "rolls back everything when the new record is invalid" do
      result = described_class.new(
        employee: employee,
        attributes: { amount_cents: -1, currency_code: "USD", pay_frequency: :annual, effective_date: Date.new(2026, 1, 1), change_reason: :promotion }
      ).call

      expect(result).not_to be_success
      expect(original.reload.end_date).to be_nil
      expect(employee.compensation_records.count).to eq(1)
    end
  end

  describe "when the employee has no compensation record yet" do
    it "creates the first (current) record" do
      result = described_class.new(
        employee: employee,
        attributes: { amount_cents: 90_000_00, currency_code: "USD", pay_frequency: :annual, effective_date: Date.current, change_reason: :hire }
      ).call

      expect(result).to be_success
      expect(employee.current_compensation_record).to be_present
    end
  end
end
