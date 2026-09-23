require "rails_helper"

RSpec.describe "Api::V1::Dashboard", type: :request do
  let(:admin) { create(:admin_user) }
  let(:headers) { auth_headers_for(admin) }

  before do
    create(:exchange_rate, currency_code: "USD", rate_to_usd: 1.0)
    create(:employee, :with_current_compensation)
  end

  describe "GET /api/v1/dashboard/summary" do
    it "requires authentication" do
      get "/api/v1/dashboard/summary"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns headcount and cost totals" do
      get "/api/v1/dashboard/summary", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("headcount", "total_annual_cost_usd_cents", "average_annual_cost_usd_cents")
      expect(body["headcount"]).to eq(1)
    end
  end

  describe "GET /api/v1/dashboard/by_country" do
    it "returns an array of country breakdowns" do
      get "/api/v1/dashboard/by_country", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first).to include("label", "headcount", "total_annual_cost_usd_cents")
    end
  end

  describe "GET /api/v1/dashboard/by_department" do
    it "returns an array of department breakdowns" do
      get "/api/v1/dashboard/by_department", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end
  end

  describe "GET /api/v1/dashboard/salary_distribution" do
    it "returns an array of job-level breakdowns" do
      get "/api/v1/dashboard/salary_distribution", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first).to include("label", "headcount", "average_annual_cost_usd_cents", "min_annual_cost_usd_cents", "max_annual_cost_usd_cents")
    end
  end
end
