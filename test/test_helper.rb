ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!

class ActiveSupport::TestCase
  setup do
    QueryLens.reset_configuration!
    RubyLLM.configure do |config|
      config.anthropic_api_key = "test-api-key"
    end
  end
end
