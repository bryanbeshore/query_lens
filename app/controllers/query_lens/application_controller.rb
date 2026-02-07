module QueryLens
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session
    layout "query_lens/layouts/application"
    before_action :authenticate!

    private

    def authenticate!
      unless QueryLens.configuration.authentication.call(self)
        head :unauthorized
      end
    end

    def audit(action:, sql: nil, row_count: nil, error: nil)
      logger = QueryLens.configuration.audit_logger
      return unless logger

      entry = {
        user: current_query_lens_user,
        action: action,
        sql: sql,
        row_count: row_count,
        error: error,
        timestamp: Time.current,
        ip: request.remote_ip
      }

      logger.call(entry)
    rescue => e
      Rails.logger.error("[QueryLens] Audit logging failed: #{e.message}")
    end

    def current_query_lens_user
      method_name = QueryLens.configuration.current_user_method
      return nil unless respond_to?(method_name, true)

      user = send(method_name)
      return "#{user.class.name}##{user.id}" if user.respond_to?(:id)

      user.to_s
    rescue
      nil
    end
  end
end
