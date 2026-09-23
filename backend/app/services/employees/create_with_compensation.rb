module Employees
  # Creates an Employee and their initial (hire) CompensationRecord in one
  # transaction — an employee should never exist without a starting salary,
  # and a compensation record should never exist without its employee.
  class CreateWithCompensation
    Result = Struct.new(:success?, :employee, :errors)

    def initialize(employee_attributes:, compensation_attributes:)
      @employee_attributes = employee_attributes.merge(employee_number: Employee.next_employee_number)
      @compensation_attributes = compensation_attributes.merge(change_reason: :hire, end_date: nil)
    end

    def call
      employee = nil

      ActiveRecord::Base.transaction do
        employee = Employee.create!(@employee_attributes)
        employee.compensation_records.create!(@compensation_attributes)
      end

      Result.new(true, employee, nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(false, nil, e.record.errors.full_messages)
    end
  end
end
