class CompensationRecord < ApplicationRecord
  belongs_to :employee, inverse_of: :compensation_records

  enum :pay_frequency, { monthly: 0, annual: 1 }
  enum :change_reason, { hire: 0, promotion: 1, annual_review: 2, market_adjustment: 3, correction: 4 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency_code, presence: true, length: { is: 3 }
  validates :effective_date, presence: true
  validates :pay_frequency, presence: true
  validates :change_reason, presence: true
  validate :end_date_on_or_after_effective_date
  validate :only_one_current_record_per_employee, if: -> { end_date.nil? }

  scope :current, -> { where(end_date: nil) }
  scope :historical, -> { where.not(end_date: nil) }
  scope :ordered, -> { order(effective_date: :desc) }

  before_validation { currency_code&.upcase! }

  # Normalizes pay frequency to an annual figure so records paid on different
  # cadences (or in different currencies, once combined with ExchangeRate)
  # can be aggregated for reporting.
  def annual_amount_cents
    monthly? ? amount_cents * 12 : amount_cents
  end

  private

  def end_date_on_or_after_effective_date
    return unless end_date && effective_date
    return if end_date >= effective_date

    errors.add(:end_date, "can't be before effective date")
  end

  # Backs up the DB partial unique index (see the compensation_records
  # migration) with a validation error that's friendlier than a raised
  # ActiveRecord::RecordNotUnique.
  def only_one_current_record_per_employee
    return unless employee_id

    existing = CompensationRecord.current.where(employee_id: employee_id)
    existing = existing.where.not(id: id) if persisted?

    errors.add(:base, "employee already has a current compensation record") if existing.exists?
  end
end
