module SeedData
  # Produces plain attribute hashes (not ActiveRecord instances) for bulk
  # insert_all — building and validating 10,000 individual Employee objects
  # is unnecessary work for data we already know is well-formed.
  class EmployeeGenerator
    COUNTRY_WEIGHTS = { "ID" => 35, "IN" => 20, "US" => 15, "SG" => 15, "MY" => 10, "AU" => 5 }.freeze
    LEVEL_WEIGHTS = { 1 => 30, 2 => 28, 3 => 22, 4 => 12, 5 => 6, 6 => 2 }.freeze
    STATUS_WEIGHTS = { active: 92, on_leave: 3, terminated: 5 }.freeze
    MAX_TENURE_DAYS = 8 * 365
    META_KEYS = %i[job_level_rank currency_code].freeze

    # Strips the seed-only metadata keys so the hash can be passed straight
    # to Employee.insert_all.
    def self.db_attributes(attrs)
      attrs.except(*META_KEYS)
    end

    def initialize(countries:, departments:, job_levels:, reference_date: Date.current, starting_number: 1)
      @countries_by_code = countries.index_by(&:code)
      @departments = departments
      @job_levels_by_rank = job_levels.index_by(&:rank)
      @reference_date = reference_date
      @starting_number = starting_number
    end

    def generate(count)
      Array.new(count) { |i| build_attributes(@starting_number + i) }
    end

    private

    def build_attributes(number)
      country = @countries_by_code.fetch(Weighted.sample(COUNTRY_WEIGHTS))
      department = @departments.sample
      job_level = @job_levels_by_rank.fetch(Weighted.sample(LEVEL_WEIGHTS))
      status = Weighted.sample(STATUS_WEIGHTS)
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      hire_date = @reference_date - rand(30..MAX_TENURE_DAYS).days
      termination_date = termination_date_for(status, hire_date)

      {
        employee_number: format("EMP%06d", number),
        first_name: first_name,
        last_name: last_name,
        work_email: "#{first_name.downcase}.#{last_name.downcase}.#{number}@acme.test",
        country_id: country.id,
        department_id: department.id,
        job_level_id: job_level.id,
        job_title: ReferenceData::TITLES_BY_DEPARTMENT.fetch(department.name)[job_level.rank - 1],
        employment_status: Employee.employment_statuses.fetch(status.to_s),
        hire_date: hire_date,
        termination_date: termination_date,
        created_at: Time.current,
        updated_at: Time.current
      }.merge(
        # Not real `employees` columns — carried alongside so the caller can
        # generate this employee's compensation history without a second
        # lookup. Stripped out before the employees insert_all (see
        # DB_ONLY_COLUMNS / db/seeds.rb).
        job_level_rank: job_level.rank,
        currency_code: country.currency_code
      )
    end

    def termination_date_for(status, hire_date)
      return nil unless status == :terminated

      tenure_days = (@reference_date - hire_date).to_i
      hire_date + rand(30..[ tenure_days, 31 ].max).days
    end
  end
end
