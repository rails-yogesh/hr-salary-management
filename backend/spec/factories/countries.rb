FactoryBot.define do
  factory :country do
    sequence(:code) { |n| (("A".ord + (n / 26) % 26).chr + ("A".ord + n % 26).chr) }
    sequence(:name) { |n| "Country #{n}" }
    currency_code { "USD" }
  end
end
