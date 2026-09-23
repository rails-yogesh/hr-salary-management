class ExchangeRate < ApplicationRecord
  validates :currency_code, presence: true, uniqueness: true, length: { is: 3 }
  validates :rate_to_usd, presence: true, numericality: { greater_than: 0 }
  validates :as_of_date, presence: true

  before_validation { currency_code&.upcase! }

  def self.usd_cents_for(amount_cents:, currency_code:)
    return amount_cents if currency_code == "USD"

    rate = find_by(currency_code: currency_code)
    raise ArgumentError, "no exchange rate for #{currency_code}" unless rate

    (amount_cents * rate.rate_to_usd).round
  end
end
