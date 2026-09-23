# Security review 2026-09-23 (SEC-M1): there is exactly one admin account
# in the whole system, and /api/v1/login had no throttling at all — a
# realistic, low-cost brute-force target. Two independent throttles (by
# IP and by the attempted email) so an attacker can't dodge one by
# spreading requests across the other dimension.
class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  LOGIN_LIMIT = 5
  LOGIN_PERIOD = 20.seconds

  throttle("logins/ip", limit: LOGIN_LIMIT, period: LOGIN_PERIOD) do |req|
    req.ip if login_attempt?(req)
  end

  throttle("logins/email", limit: LOGIN_LIMIT, period: LOGIN_PERIOD) do |req|
    req.params["email"].to_s.strip.downcase.presence if login_attempt?(req)
  end

  def self.login_attempt?(req)
    req.post? && req.path == "/api/v1/login"
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Too many login attempts. Please try again in a moment." }.to_json ]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
