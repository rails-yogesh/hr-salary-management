require "rails_helper"

RSpec.describe Employees::CreateWithCompensation do
  let(:country) { create(:country) }
  let(:department) { create(:department) }
  let(:job_level) { create(:job_level) }

  let(:employee_attributes) do
    {
      first_name: "Ada",
      last_name: "Lovelace",
      work_email: "ada.lovelace@acme.test",
      job_title: "Software Engineer",
      hire_date: Date.current,
      country_id: country.id,
      department_id: department.id,
      job_level_id: job_level.id
    }
  end

  let(:compensation_attributes) do
    { amount_cents: 100_000_00, currency_code: "USD", pay_frequency: :annual, effective_date: Date.current }
  end

  subject(:service) { described_class.new(employee_attributes: employee_attributes, compensation_attributes: compensation_attributes) }

  it "creates the employee with a server-generated employee number" do
    result = service.call

    expect(result).to be_success
    expect(result.employee).to be_persisted
    expect(result.employee.employee_number).to eq("EMP000001")
  end

  it "creates a current compensation record with change_reason hire" do
    result = service.call

    record = result.employee.current_compensation_record
    expect(record).to be_present
    expect(record).to be_hire
    expect(record.amount_cents).to eq(100_000_00)
  end

  it "rolls back the employee if the compensation record is invalid" do
    invalid_compensation = compensation_attributes.merge(amount_cents: -1)
    service = described_class.new(employee_attributes: employee_attributes, compensation_attributes: invalid_compensation)

    result = service.call

    expect(result).not_to be_success
    expect(result.errors).to be_present
    expect(Employee.count).to eq(0)
  end

  it "rolls back if the employee attributes are invalid" do
    invalid_attrs = employee_attributes.merge(work_email: "not-an-email")
    service = described_class.new(employee_attributes: invalid_attrs, compensation_attributes: compensation_attributes)

    result = service.call

    expect(result).not_to be_success
    expect(Employee.count).to eq(0)
    expect(CompensationRecord.count).to eq(0)
  end

  it "rejects (and rolls back) a starting compensation record backdated before the hire date (security review 2026-09-23, SEC-H1)" do
    attrs = employee_attributes.merge(hire_date: Date.new(2026, 1, 1))
    backdated_compensation = compensation_attributes.merge(effective_date: Date.new(2020, 1, 1))
    service = described_class.new(employee_attributes: attrs, compensation_attributes: backdated_compensation)

    result = service.call

    expect(result).not_to be_success
    expect(result.errors.join).to match(/can't be before the employee's hire date/)
    expect(Employee.count).to eq(0)
    expect(CompensationRecord.count).to eq(0)
  end
end
