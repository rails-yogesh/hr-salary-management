FactoryBot.define do
  factory :exchange_rate do
    sequence(:currency_code) { |n| format("X%02d", n)[0, 3].upcase }
    rate_to_usd { 1.0 }
    as_of_date { Date.current }
  end
end
