class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true
  validates :currency_code, presence: true, length: { is: 3 }

  before_validation { code&.upcase!; currency_code&.upcase! }
end
