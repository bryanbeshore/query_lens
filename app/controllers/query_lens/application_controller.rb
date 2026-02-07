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
  end
end
