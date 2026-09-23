module AuthHelpers
  def auth_headers_for(admin_user)
    token = JsonWebToken.encode(admin_user_id: admin_user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
