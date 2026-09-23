module Api
  module V1
    # Reference data for populating dropdowns in the employee create/edit forms.
    class LookupsController < BaseController
      def index
        render json: {
          countries: Country.order(:name).map { |c| { id: c.id, code: c.code, name: c.name, currency_code: c.currency_code } },
          departments: Department.order(:name).map { |d| { id: d.id, name: d.name } },
          job_levels: JobLevel.order(:rank).map { |l| { id: l.id, name: l.name, rank: l.rank } }
        }
      end
    end
  end
end
