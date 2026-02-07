Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.active_support.deprecation = :stderr
  config.secret_key_base = "test-secret-key-base-for-query-lens-dummy-app"
end
