require "rails_helper"

RSpec.describe SeedData::EmployeeGenerator do
  let(:refs) { SeedData::ReferenceData.apply!(as_of_date: Date.current) }
  let(:generator) do
    described_class.new(
      countries: refs[:countries],
      departments: refs[:departments],
      job_levels: refs[:job_levels],
      reference_date: Date.current,
      starting_number: 1
    )
  end

  describe "#generate" do
    subject(:attrs_list) { generator.generate(50) }

    it "generates the requested count" do
      expect(attrs_list.size).to eq(50)
    end

    it "produces unique employee numbers and emails" do
      expect(attrs_list.map { |a| a[:employee_number] }.uniq.size).to eq(50)
      expect(attrs_list.map { |a| a[:work_email] }.uniq.size).to eq(50)
    end

    it "only references real, persisted reference data" do
      country_ids = refs[:countries].map(&:id)
      department_ids = refs[:departments].map(&:id)
      job_level_ids = refs[:job_levels].map(&:id)

      attrs_list.each do |attrs|
        expect(country_ids).to include(attrs[:country_id])
        expect(department_ids).to include(attrs[:department_id])
        expect(job_level_ids).to include(attrs[:job_level_id])
      end
    end

    it "produces attributes that pass Employee validations" do
      attrs_list.each do |attrs|
        employee = Employee.new(SeedData::EmployeeGenerator.db_attributes(attrs))
        expect(employee).to be_valid, -> { employee.errors.full_messages.join(", ") }
      end
    end

    it "only sets a termination_date for terminated employees" do
      attrs_list.each do |attrs|
        status = Employee.employment_statuses.key(attrs[:employment_status])

        if status == "terminated"
          expect(attrs[:termination_date]).to be_present
          expect(attrs[:termination_date]).to be > attrs[:hire_date]
        else
          expect(attrs[:termination_date]).to be_nil
        end
      end
    end

    it "never hires someone in the future" do
      attrs_list.each { |attrs| expect(attrs[:hire_date]).to be <= Date.current }
    end
  end

  describe ".db_attributes" do
    it "strips seed-only metadata keys" do
      attrs = generator.generate(1).first

      expect(SeedData::EmployeeGenerator.db_attributes(attrs).keys).not_to include(:job_level_rank, :currency_code)
    end
  end
end
