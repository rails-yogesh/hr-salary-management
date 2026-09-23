class Employee < ApplicationRecord
  belongs_to :country
  belongs_to :department
  belongs_to :job_level
  has_many :compensation_records, dependent: :destroy, inverse_of: :employee
  has_one :current_compensation_record,
    -> { where(end_date: nil) },
    class_name: "CompensationRecord",
    inverse_of: :employee

  enum :employment_status, { active: 0, terminated: 1, on_leave: 2 }

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, :last_name, :job_title, presence: true
  validates :work_email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :hire_date, presence: true
  validates :termination_date, presence: true, if: :terminated?
  validate :termination_date_not_before_hire_date

  scope :search, ->(query) {
    next all if query.blank?

    sanitized = "%#{sanitize_sql_like(query)}%"
    where(
      "employee_number ILIKE :q OR work_email ILIKE :q OR first_name || ' ' || last_name ILIKE :q",
      q: sanitized
    )
  }

  # Anyone still drawing a salary — active or on leave. Used by dashboard
  # cost/headcount reporting; terminated employees are excluded because
  # they're no longer being paid.
  scope :currently_employed, -> { where(employment_status: %i[active on_leave]) }

  # Employee numbers are server-generated (never client-supplied) so HR
  # doesn't have to invent IDs and two concurrent creates can't collide.
  def self.next_employee_number
    last_number = order(Arel.sql("employee_number DESC")).limit(1).pick(:employee_number)
    sequence = last_number ? last_number.delete_prefix("EMP").to_i + 1 : 1
    format("EMP%06d", sequence)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def termination_date_not_before_hire_date
    return unless termination_date && hire_date
    return if termination_date >= hire_date

    errors.add(:termination_date, "can't be before hire date")
  end
end
