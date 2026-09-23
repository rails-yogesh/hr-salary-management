FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "hr#{n}@acme.test" }
    password { "correct-horse-battery-staple" }
  end
end
