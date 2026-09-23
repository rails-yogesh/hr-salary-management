module Api
  module V1
    class CompensationRecordsController < BaseController
      before_action :set_employee

      def create
        result = Employees::RecordCompensationChange.new(employee: @employee, attributes: compensation_params).call

        if result.success?
          render json: EmployeeSerializer.detail(@employee), status: :created
        else
          render json: { error: result.errors }, status: :unprocessable_content
        end
      end

      private

      def set_employee
        @employee = Employee.find(params[:employee_id])
      end

      def compensation_params
        params.require(:compensation_record).permit(:amount_cents, :currency_code, :pay_frequency, :effective_date, :change_reason, :note)
      end
    end
  end
end
