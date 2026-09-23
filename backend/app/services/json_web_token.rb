# Minimal HS256 JWT wrapper for the single-admin auth scheme (see
# docs/ARCHITECTURE.md for why this app deliberately has no RBAC/SSO).
class JsonWebToken
  ALGORITHM = "HS256".freeze

  def self.encode(payload, expires_at = 24.hours.from_now)
    payload = payload.merge(exp: expires_at.to_i)
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
