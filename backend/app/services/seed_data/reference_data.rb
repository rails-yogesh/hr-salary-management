module SeedData
  # The reference data (countries, departments, job levels, exchange rates)
  # that both the seed script and, indirectly, the app's dropdowns rely on.
  # Exchange rates are a static dated snapshot, not a live feed — see
  # docs/REQUIREMENTS.md for why.
  module ReferenceData
    COUNTRIES = [
      { code: "ID", name: "Indonesia", currency_code: "IDR" },
      { code: "US", name: "United States", currency_code: "USD" },
      { code: "SG", name: "Singapore", currency_code: "SGD" },
      { code: "IN", name: "India", currency_code: "INR" },
      { code: "MY", name: "Malaysia", currency_code: "MYR" },
      { code: "AU", name: "Australia", currency_code: "AUD" }
    ].freeze

    DEPARTMENTS = [
      "Engineering", "Sales", "Finance", "Human Resources",
      "Marketing", "Operations", "Customer Support"
    ].freeze

    # rank orders the pay bands low -> high; annual_usd_band is the midpoint
    # of that level's salary band in USD, before country/variance adjustment.
    JOB_LEVELS = [
      { name: "L1 - Associate", rank: 1, annual_usd_band: 30_000 },
      { name: "L2 - Professional", rank: 2, annual_usd_band: 45_000 },
      { name: "L3 - Senior", rank: 3, annual_usd_band: 65_000 },
      { name: "L4 - Lead", rank: 4, annual_usd_band: 90_000 },
      { name: "L5 - Manager", rank: 5, annual_usd_band: 120_000 },
      { name: "L6 - Director", rank: 6, annual_usd_band: 170_000 }
    ].freeze

    # rate_to_usd = value of 1 unit of the currency in USD, as of the seed
    # date. Static snapshot: see docs/REQUIREMENTS.md "live FX rates" gap.
    EXCHANGE_RATES = {
      "USD" => 1.0,
      "IDR" => 0.000063,
      "SGD" => 0.74,
      "INR" => 0.012,
      "MYR" => 0.21,
      "AUD" => 0.65
    }.freeze

    # Countries where the seed data models pay as a monthly figure rather
    # than annual — exercises CompensationRecord#annual_amount_cents.
    MONTHLY_PAY_CURRENCIES = %w[IDR SGD INR MYR].freeze

    TITLES_BY_DEPARTMENT = {
      "Engineering" => [ "Software Engineer I", "Software Engineer II", "Senior Software Engineer", "Staff Engineer", "Engineering Manager", "Director of Engineering" ],
      "Sales" => [ "Sales Development Rep", "Account Executive", "Senior Account Executive", "Sales Team Lead", "Sales Manager", "Director of Sales" ],
      "Finance" => [ "Finance Analyst", "Finance Associate", "Senior Finance Analyst", "Finance Lead", "Finance Manager", "Director of Finance" ],
      "Human Resources" => [ "HR Coordinator", "HR Generalist", "Senior HR Generalist", "HR Business Partner", "HR Manager", "Director of HR" ],
      "Marketing" => [ "Marketing Associate", "Marketing Specialist", "Senior Marketing Specialist", "Marketing Lead", "Marketing Manager", "Director of Marketing" ],
      "Operations" => [ "Operations Associate", "Operations Analyst", "Senior Operations Analyst", "Operations Lead", "Operations Manager", "Director of Operations" ],
      "Customer Support" => [ "Support Associate", "Support Specialist", "Senior Support Specialist", "Support Team Lead", "Support Manager", "Director of Support" ]
    }.freeze

    def self.apply!(as_of_date: Date.current)
      countries = COUNTRIES.map do |attrs|
        Country.find_or_create_by!(code: attrs[:code]) do |c|
          c.name = attrs[:name]
          c.currency_code = attrs[:currency_code]
        end
      end

      departments = DEPARTMENTS.map { |name| Department.find_or_create_by!(name: name) }

      job_levels = JOB_LEVELS.map do |attrs|
        JobLevel.find_or_create_by!(rank: attrs[:rank]) { |jl| jl.name = attrs[:name] }
      end

      EXCHANGE_RATES.each do |currency_code, rate|
        ExchangeRate.find_or_initialize_by(currency_code: currency_code)
          .update!(rate_to_usd: rate, as_of_date: as_of_date)
      end

      { countries: countries, departments: departments, job_levels: job_levels }
    end

    def self.level_bands
      JOB_LEVELS.to_h { |attrs| [ attrs[:rank], attrs[:annual_usd_band] ] }
    end
  end
end
