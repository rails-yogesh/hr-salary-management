module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_admin_user!

      def show
        render json: { status: "ok" }
      end
    end
  end
end
