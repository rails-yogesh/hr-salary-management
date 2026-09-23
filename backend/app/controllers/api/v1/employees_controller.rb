module Api
  module V1
    class EmployeesController < BaseController
      include Paginatable

      before_action :set_employee, only: %i[show update terminate]

      def index
        employees = Employee.includes(:country, :department, :job_level, :current_compensation_record)
        employees = employees.where(country_id: params[:country_id]) if params[:country_id].present?
        employees = employees.where(department_id: params[:department_id]) if params[:department_id].present?
        employees = filter_by_status(employees)
        employees = employees.search(params[:q])
        employees = paginate(employees.order(:last_name, :first_name))

        render json: {
          employees: employees.map { |e| EmployeeSerializer.list_item(e) },
          meta: pagination_meta(employees)
        }
      end

      def show
        render json: EmployeeSerializer.detail(@employee)
      end

      def create
        result = Employees::CreateWithCompensation.new(
          employee_attributes: employee_params,
          compensation_attributes: compensation_params
        ).call

        if result.success?
          render json: EmployeeSerializer.detail(result.employee), status: :created
        else
          render json: { error: result.errors }, status: :unprocessable_content
        end
      end

      def update
        @employee.update!(employee_update_params)
        render json: EmployeeSerializer.detail(@employee)
      end

      def terminate
        @employee.update!(
          employment_status: :terminated,
          termination_date: params.fetch(:termination_date, Date.current)
        )
        render json: EmployeeSerializer.detail(@employee)
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def filter_by_status(scope)
        status = params[:employment_status]
        return scope unless status.present? && Employee.employment_statuses.key?(status)

        scope.where(employment_status: status)
      end

      def employee_params
        params.require(:employee).permit(
          :first_name, :last_name, :work_email, :job_title,
          :country_id, :department_id, :job_level_id, :hire_date
        )
      end

      def employee_update_params
        params.require(:employee).permit(
          :first_name, :last_name, :work_email, :job_title,
          :country_id, :department_id, :job_level_id
        )
      end

      def compensation_params
        params.require(:compensation).permit(:amount_cents, :currency_code, :pay_frequency, :effective_date)
      end
    end
  end
end
