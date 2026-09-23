require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let(:admin) { create(:admin_user) }
  let(:headers) { auth_headers_for(admin) }

  describe "GET /api/v1/employees" do
    it "requires authentication" do
      get "/api/v1/employees"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a paginated list ordered by name" do
      create(:employee, :with_current_compensation, first_name: "Zara", last_name: "Ziegler")
      create(:employee, :with_current_compensation, first_name: "Amir", last_name: "Aziz")

      get "/api/v1/employees", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["employees"].map { |e| e["full_name"] }).to eq([ "Amir Aziz", "Zara Ziegler" ])
      expect(body["meta"]).to include("current_page" => 1, "total_count" => 2)
    end

    it "includes the current compensation summary" do
      employee = create(:employee, :with_current_compensation)

      get "/api/v1/employees", headers: headers

      body = JSON.parse(response.body)
      returned = body["employees"].find { |e| e["id"] == employee.id }
      expect(returned["current_compensation"]["amount_cents"]).to eq(employee.current_compensation_record.amount_cents)
    end

    it "filters by country, department, and employment_status" do
      country = create(:country)
      match = create(:employee, :with_current_compensation, country: country, employment_status: :active)
      create(:employee, :with_current_compensation, :terminated)

      get "/api/v1/employees", params: { country_id: country.id, employment_status: "active" }, headers: headers

      body = JSON.parse(response.body)
      expect(body["employees"].map { |e| e["id"] }).to contain_exactly(match.id)
    end

    it "searches by name, employee number, or email" do
      match = create(:employee, :with_current_compensation, first_name: "Grace", last_name: "Hopper")
      create(:employee, :with_current_compensation, first_name: "Ada", last_name: "Lovelace")

      get "/api/v1/employees", params: { q: "hopper" }, headers: headers

      body = JSON.parse(response.body)
      expect(body["employees"].map { |e| e["id"] }).to contain_exactly(match.id)
    end

    it "paginates results" do
      create_list(:employee, 3, :with_current_compensation)

      get "/api/v1/employees", params: { per_page: 2, page: 2 }, headers: headers

      body = JSON.parse(response.body)
      expect(body["employees"].size).to eq(1)
      expect(body["meta"]).to include("current_page" => 2, "total_pages" => 2)
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the employee with full compensation history" do
      employee = create(:employee, :with_current_compensation)

      get "/api/v1/employees/#{employee.id}", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(employee.id)
      expect(body["compensation_history"].size).to eq(1)
    end

    it "returns 404 for an unknown employee" do
      get "/api/v1/employees/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employees" do
    let(:country) { create(:country) }
    let(:department) { create(:department) }
    let(:job_level) { create(:job_level) }

    let(:valid_params) do
      {
        employee: {
          first_name: "Ada", last_name: "Lovelace", work_email: "ada@acme.test",
          job_title: "Engineer", hire_date: Date.current.to_s,
          country_id: country.id, department_id: department.id, job_level_id: job_level.id
        },
        compensation: { amount_cents: 100_000_00, currency_code: "USD", pay_frequency: "annual", effective_date: Date.current.to_s }
      }
    end

    it "requires authentication" do
      post "/api/v1/employees", params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates an employee with an initial compensation record" do
      expect {
        post "/api/v1/employees", params: valid_params, headers: headers
      }.to change(Employee, :count).by(1).and change(CompensationRecord, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["full_name"]).to eq("Ada Lovelace")
      expect(body["current_compensation"]["amount_cents"]).to eq(100_000_00)
    end

    it "returns 422 and creates nothing when compensation is invalid" do
      invalid_params = valid_params.deep_merge(compensation: { amount_cents: -1 })

      expect {
        post "/api/v1/employees", params: invalid_params, headers: headers
      }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    it "updates profile fields" do
      employee = create(:employee, :with_current_compensation)

      patch "/api/v1/employees/#{employee.id}", params: { employee: { job_title: "Principal Engineer" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(employee.reload.job_title).to eq("Principal Engineer")
    end

    it "returns 422 for invalid updates" do
      employee = create(:employee, :with_current_compensation)

      patch "/api/v1/employees/#{employee.id}", params: { employee: { work_email: "not-an-email" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/employees/:id/terminate" do
    it "marks the employee terminated with a termination date" do
      employee = create(:employee, :with_current_compensation, employment_status: :active)

      patch "/api/v1/employees/#{employee.id}/terminate", params: { termination_date: Date.current.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      employee.reload
      expect(employee).to be_terminated
      expect(employee.termination_date).to eq(Date.current)
    end
  end
end
