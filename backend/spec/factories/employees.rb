FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| format("EMP%06d", n) }
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:work_email) { |n| "jane.doe#{n}@acme.test" }
    job_title { "Software Engineer" }
    employment_status { :active }
    hire_date { 2.years.ago.to_date }
    termination_date { nil }
    country
    department
    job_level

    trait :terminated do
      employment_status { :terminated }
      termination_date { 1.month.ago.to_date }
    end

    trait :with_current_compensation do
      after(:create) do |employee|
        create(:compensation_record, employee: employee)
      end
    end
  end
end
