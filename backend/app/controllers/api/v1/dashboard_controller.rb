module Api
  module V1
    class DashboardController < BaseController
      def summary
        render json: Dashboard::Analytics.summary
      end

      def by_country
        render json: Dashboard::Analytics.by_country
      end

      def by_department
        render json: Dashboard::Analytics.by_department
      end

      def salary_distribution
        render json: Dashboard::Analytics.salary_distribution
      end
    end
  end
end
