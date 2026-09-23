FactoryBot.define do
  factory :compensation_record do
    employee
    amount_cents { 10_000_00 }
    currency_code { "USD" }
    pay_frequency { :annual }
    effective_date { 1.year.ago.to_date }
    end_date { nil }
    change_reason { :hire }
    note { nil }
  end
end
