module Dashboard
  # Answers "how does the org pay people": headcount and payroll cost,
  # normalized to USD cents via the ExchangeRate snapshot, computed with SQL
  # aggregation (not loaded into Ruby) so it stays fast at 10k+ employees.
  #
  # Scope for all four queries: the *current* compensation record of every
  # employee who is still employed (active or on_leave) — see
  # Employee.currently_employed for why terminated employees are excluded.
  module Analytics
    # amount_cents annualized (monthly * 12, annual as-is), then converted to
    # USD cents via the joined exchange_rates row.
    ANNUAL_USD_CENTS_SQL = <<~SQL.squish
      (CASE WHEN compensation_records.pay_frequency = 0
            THEN compensation_records.amount_cents * 12
            ELSE compensation_records.amount_cents
       END) * exchange_rates.rate_to_usd
    SQL

    def self.base_scope
      CompensationRecord
        .current
        .joins(:exchange_rate)
        .joins(employee: %i[country department job_level])
        .merge(Employee.currently_employed)
    end

    def self.summary
      headcount, total_usd_cents, average_usd_cents =
        base_scope.pick(Arel.sql("COUNT(*), COALESCE(SUM(#{ANNUAL_USD_CENTS_SQL}), 0), COALESCE(AVG(#{ANNUAL_USD_CENTS_SQL}), 0)"))

      {
        headcount: headcount,
        total_annual_cost_usd_cents: total_usd_cents.round,
        average_annual_cost_usd_cents: average_usd_cents.round
      }
    end

    def self.by_country
      base_scope
        .group("countries.id", "countries.name")
        .order("countries.name")
        .pluck(Arel.sql("countries.name, COUNT(*), COALESCE(SUM(#{ANNUAL_USD_CENTS_SQL}), 0)"))
        .map { |name, headcount, total| { label: name, headcount: headcount, total_annual_cost_usd_cents: total.round } }
    end

    def self.by_department
      base_scope
        .group("departments.id", "departments.name")
        .order("departments.name")
        .pluck(Arel.sql("departments.name, COUNT(*), COALESCE(SUM(#{ANNUAL_USD_CENTS_SQL}), 0)"))
        .map { |name, headcount, total| { label: name, headcount: headcount, total_annual_cost_usd_cents: total.round } }
    end

    def self.salary_distribution
      base_scope
        .group("job_levels.id", "job_levels.name", "job_levels.rank")
        .order("job_levels.rank")
        .pluck(Arel.sql("job_levels.name, COUNT(*), COALESCE(AVG(#{ANNUAL_USD_CENTS_SQL}), 0), COALESCE(MIN(#{ANNUAL_USD_CENTS_SQL}), 0), COALESCE(MAX(#{ANNUAL_USD_CENTS_SQL}), 0)"))
        .map do |name, headcount, average, min, max|
          {
            label: name,
            headcount: headcount,
            average_annual_cost_usd_cents: average.round,
            min_annual_cost_usd_cents: min.round,
            max_annual_cost_usd_cents: max.round
          }
        end
    end
  end
end
