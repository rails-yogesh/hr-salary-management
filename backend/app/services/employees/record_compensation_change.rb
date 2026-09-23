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
      # Security review 2026-09-23 (SEC-H1): check against the latest
      # effective_date across the *entire* history, not just the current
      # record. In today's code the current record always happens to hold
      # the latest date, so this is currently equivalent — but checking
      # `current` alone silently stops being correct the moment any other
      # code path (a future backfill/correction feature, a direct console
      # fix) inserts a record without going through this service first.
      latest_effective_date = @employee.compensation_records.maximum(:effective_date)

      if latest_effective_date && effective_date && effective_date <= latest_effective_date
        return Result.new(false, nil, [ "effective_date must be after the most recent compensation record's effective date (#{latest_effective_date})" ])
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
