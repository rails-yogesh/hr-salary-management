require "rails_helper"

RSpec.describe Employee, type: :model do
  subject { build(:employee) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:country) }
  it { is_expected.to belong_to(:department) }
  it { is_expected.to belong_to(:job_level) }
  it { is_expected.to have_many(:compensation_records) }
  it { is_expected.to validate_presence_of(:employee_number) }
  it { is_expected.to validate_uniqueness_of(:employee_number) }
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:job_title) }
  it { is_expected.to validate_presence_of(:hire_date) }
  it { is_expected.to define_enum_for(:employment_status).with_values(active: 0, terminated: 1, on_leave: 2) }

  describe "work_email" do
    it "rejects an invalid format" do
      employee = build(:employee, work_email: "not-an-email")

      expect(employee).not_to be_valid
      expect(employee.errors[:work_email]).to be_present
    end

    it "rejects a duplicate regardless of case" do
      create(:employee, work_email: "jane.doe@acme.test")
      duplicate = build(:employee, work_email: "JANE.DOE@acme.test")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:work_email]).to be_present
    end
  end

  describe "termination_date" do
    it "is required when the employee is terminated" do
      employee = build(:employee, employment_status: :terminated, termination_date: nil)

      expect(employee).not_to be_valid
      expect(employee.errors[:termination_date]).to be_present
    end

    it "cannot be before the hire date" do
      employee = build(:employee, :terminated, hire_date: Date.new(2020, 1, 1), termination_date: Date.new(2019, 1, 1))

      expect(employee).not_to be_valid
      expect(employee.errors[:termination_date]).to include("can't be before hire date")
    end

    it "is not required for an active employee" do
      employee = build(:employee, employment_status: :active, termination_date: nil)

      expect(employee).to be_valid
    end
  end

  describe "#full_name" do
    it "joins first and last name" do
      employee = build(:employee, first_name: "Ada", last_name: "Lovelace")

      expect(employee.full_name).to eq("Ada Lovelace")
    end
  end

  describe ".search" do
    it "matches by employee number, email, or full name" do
      match = create(:employee, employee_number: "EMP000123", first_name: "Grace", last_name: "Hopper", work_email: "grace.hopper@acme.test")
      create(:employee, employee_number: "EMP000999", first_name: "Ada", last_name: "Lovelace", work_email: "ada.lovelace@acme.test")

      expect(Employee.search("hopper")).to contain_exactly(match)
      expect(Employee.search("EMP000123")).to contain_exactly(match)
      expect(Employee.search("grace.hopper")).to contain_exactly(match)
    end

    it "returns everyone when the query is blank" do
      create_list(:employee, 2)

      expect(Employee.search(nil).count).to eq(2)
      expect(Employee.search("").count).to eq(2)
    end
  end

  describe ".currently_employed" do
    it "includes active and on_leave but excludes terminated" do
      active = create(:employee, employment_status: :active)
      on_leave = create(:employee, employment_status: :on_leave)
      create(:employee, :terminated)

      expect(Employee.currently_employed).to contain_exactly(active, on_leave)
    end
  end

  describe ".next_employee_number" do
    it "starts at EMP000001 when there are no employees" do
      expect(Employee.next_employee_number).to eq("EMP000001")
    end

    it "increments past the highest existing number" do
      create(:employee, employee_number: "EMP000042")

      expect(Employee.next_employee_number).to eq("EMP000043")
    end
  end
end
