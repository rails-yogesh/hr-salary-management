module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_admin_user!, only: :create

      def create
        admin = AdminUser.find_by(email: params[:email].to_s.downcase)

        if admin&.authenticate(params[:password].to_s)
          render json: { token: JsonWebToken.encode(admin_user_id: admin.id), email: admin.email }, status: :created
        else
          render json: { error: "invalid email or password" }, status: :unauthorized
        end
      end
    end
  end
end
