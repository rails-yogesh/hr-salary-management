module SeedData
  # Builds a realistic, valid compensation *history* for one employee: 1-3
  # dated records with strictly increasing effective_date, contiguous
  # end_date/effective_date boundaries, and exactly one open-ended (current)
  # record — the same invariant CompensationRecord enforces at the DB level.
  class CompensationGenerator
    RAISE_REASONS = %w[annual_review promotion market_adjustment].freeze
    MIN_TENURE_FOR_ONE_RAISE = 365
    MIN_TENURE_FOR_TWO_RAISES = 730

    # random: injectable for deterministic tests; production callers can
    # leave it as the default (a real, unseeded source of randomness).
    def initialize(level_bands:, exchange_rates:, reference_date: Date.current, random: Random.new)
      @level_bands = level_bands
      @exchange_rates = exchange_rates
      @reference_date = reference_date
      @random = random
    end

    # employee_id: the persisted Employee's id
    # job_level_rank/currency_code/hire_date: from the employee's generated attributes
    def generate_for(employee_id:, job_level_rank:, currency_code:, hire_date:)
      effective_dates = build_effective_dates(hire_date)
      annual_usd = @level_bands.fetch(job_level_rank) * @random.rand(0.85..1.15)
      rate = @exchange_rates.fetch(currency_code)
      monthly = ReferenceData::MONTHLY_PAY_CURRENCIES.include?(currency_code)

      effective_dates.each_with_index.map do |effective_date, index|
        annual_usd *= @random.rand(1.05..1.20) if index.positive?

        {
          employee_id: employee_id,
          amount_cents: to_amount_cents(annual_usd, rate, monthly),
          currency_code: currency_code,
          pay_frequency: CompensationRecord.pay_frequencies.fetch(monthly ? "monthly" : "annual"),
          effective_date: effective_date,
          end_date: effective_dates[index + 1]&.prev_day,
          change_reason: CompensationRecord.change_reasons.fetch(index.zero? ? "hire" : RAISE_REASONS.sample(random: @random)),
          note: nil,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    private

    # Always starts at hire_date; probabilistically adds 1-2 later raise
    # dates, each 12-18 months after the previous, never reaching today.
    def build_effective_dates(hire_date)
      tenure_days = (@reference_date - hire_date).to_i
      target_raises =
        if tenure_days >= MIN_TENURE_FOR_TWO_RAISES && @random.rand < 0.15
          2
        elsif tenure_days >= MIN_TENURE_FOR_ONE_RAISE && @random.rand < 0.35
          1
        else
          0
        end

      dates = [ hire_date ]
      target_raises.times do
        candidate = dates.last + @random.rand(365..540).days
        break if candidate >= @reference_date

        dates << candidate
      end
      dates
    end

    def to_amount_cents(annual_usd, rate_to_usd, monthly)
      local_annual = annual_usd / rate_to_usd
      local_amount = monthly ? local_annual / 12.0 : local_annual
      (local_amount * 100).round
    end
  end
end
