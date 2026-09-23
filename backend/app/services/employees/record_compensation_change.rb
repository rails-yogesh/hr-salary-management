module Employees
  # Records a raise/promotion/correction for an employee who already has a
  # compensation record: closes the current record's end_date and opens a
  # new current record, atomically. This is the only supported way to change
  # an employee's pay — compensation is never edited in place (see
  # CompensationRecord's append-only invariant).
  class RecordCompensationChange
    Result = Struct.new(:success?, :compensation_record, :errors)

    def initialize(employee:, attributes:)
      @employee = employee
      @attributes = attributes
    end

    def call
      current = @employee.current_compensation_record
      effective_date = parse_date(@attributes[:effective_date])

      if current && effective_date && effective_date <= current.effective_date
        return Result.new(false, nil, [ "effective_date must be after the current record's effective date (#{current.effective_date})" ])
      end

      new_record = nil
      ActiveRecord::Base.transaction do
        current&.update!(end_date: effective_date - 1.day)
        new_record = @employee.compensation_records.create!(@attributes.merge(end_date: nil))
      end
      # The employee's `current_compensation_record` (has_one) and
      # `compensation_records` associations may already be memoized (e.g.
      # from the `current` lookup above) — reload so callers see the change.
      @employee.reload

      Result.new(true, new_record, nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(false, nil, e.record.errors.full_messages)
    end

    private

    def parse_date(value)
      value.is_a?(Date) ? value : Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
