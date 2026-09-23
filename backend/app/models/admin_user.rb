class AdminUser < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  # Security review 2026-09-23 (SEC-M2): has_secure_password alone permits
  # any non-blank password, including a single character. allow_nil so this
  # doesn't fire on calls (e.g. `authenticate`) that don't touch password.
  validates :password, length: { minimum: 12 }, allow_nil: true

  before_validation { email&.downcase! }
end
