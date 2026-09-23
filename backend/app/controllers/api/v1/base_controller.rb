module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_admin_user!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

      attr_reader :current_admin_user

      private

      def authenticate_admin_user!
        payload = decode_bearer_token
        admin = payload && AdminUser.find_by(id: payload[:admin_user_id])

        if admin
          @current_admin_user = admin
        else
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end

      def decode_bearer_token
        token = request.headers["Authorization"]&.split(" ")&.last
        token && JsonWebToken.decode(token)
      end

      def render_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
