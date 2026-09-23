require "rails_helper"

RSpec.describe "Api::V1::CompensationRecords", type: :request do
  let(:admin) { create(:admin_user) }
  let(:headers) { auth_headers_for(admin) }
  let(:employee) { create(:employee) }
  let!(:original) { create(:compensation_record, employee: employee, effective_date: Date.new(2025, 1, 1), amount_cents: 100_000_00) }

  def raise_params(overrides = {})
    {
      compensation_record: {
        amount_cents: 115_000_00, currency_code: "USD", pay_frequency: "annual",
        effective_date: Date.new(2026, 1, 1).to_s, change_reason: "promotion"
      }.merge(overrides)
    }
  end

  it "requires authentication" do
    post "/api/v1/employees/#{employee.id}/compensation_records", params: raise_params

    expect(response).to have_http_status(:unauthorized)
  end

  it "records a raise, closing the previous record and opening a new one" do
    post "/api/v1/employees/#{employee.id}/compensation_records", params: raise_params, headers: headers

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["current_compensation"]["amount_cents"]).to eq(115_000_00)
    expect(body["compensation_history"].size).to eq(2)

    expect(original.reload.end_date).to eq(Date.new(2025, 12, 31))
  end

  it "returns 422 when the effective_date does not come after the current record" do
    post "/api/v1/employees/#{employee.id}/compensation_records",
      params: raise_params(effective_date: Date.new(2024, 1, 1).to_s), headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(employee.compensation_records.count).to eq(1)
  end

  it "returns 422 for an invalid amount and leaves history untouched" do
    post "/api/v1/employees/#{employee.id}/compensation_records",
      params: raise_params(amount_cents: -5), headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(original.reload.end_date).to be_nil
  end

  it "returns 404 for an unknown employee" do
    post "/api/v1/employees/999999/compensation_records", params: raise_params, headers: headers

    expect(response).to have_http_status(:not_found)
  end
end
