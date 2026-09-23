FactoryBot.define do
  factory :job_level do
    sequence(:name) { |n| "L#{n}" }
    sequence(:rank) { |n| n }
  end
end
