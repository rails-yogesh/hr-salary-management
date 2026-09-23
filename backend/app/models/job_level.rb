class JobLevel < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :rank, presence: true, uniqueness: true

  default_scope { order(:rank) }
end
