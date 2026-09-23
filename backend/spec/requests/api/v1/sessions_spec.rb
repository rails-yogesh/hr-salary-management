require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    let!(:admin) { create(:admin_user, email: "hr@acme.test", password: "correct-horse-battery-staple") }

    it "returns a token for valid credentials" do
      post "/api/v1/login", params: { email: "hr@acme.test", password: "correct-horse-battery-staple" }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(JsonWebToken.decode(body["token"])).to include("admin_user_id" => admin.id)
    end

    it "is case-insensitive on email" do
      post "/api/v1/login", params: { email: "HR@ACME.test", password: "correct-horse-battery-staple" }

      expect(response).to have_http_status(:created)
    end

    it "rejects an incorrect password" do
      post "/api/v1/login", params: { email: "hr@acme.test", password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an unknown email" do
      post "/api/v1/login", params: { email: "nobody@acme.test", password: "whatever" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
