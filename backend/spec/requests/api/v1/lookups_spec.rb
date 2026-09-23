require "rails_helper"

RSpec.describe "Api::V1::Lookups", type: :request do
  let(:admin) { create(:admin_user) }

  it "requires authentication" do
    get "/api/v1/lookups"

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns countries, departments, and job levels" do
    country = create(:country)
    department = create(:department)
    job_level = create(:job_level)

    get "/api/v1/lookups", headers: auth_headers_for(admin)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["countries"].pluck("id")).to include(country.id)
    expect(body["departments"].pluck("id")).to include(department.id)
    expect(body["job_levels"].pluck("id")).to include(job_level.id)
  end
end
