QueryLens.configure do |config|
  # Required: Your Anthropic API key
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]

  # Claude model to use (default: "claude-sonnet-4-5-20250929")
  # config.model = "claude-sonnet-4-5-20250929"

  # Maximum rows returned per query (default: 1000)
  # config.max_rows = 1000

  # Query timeout in seconds (default: 30)
  # config.query_timeout = 30

  # Tables to exclude from AI schema context
  # config.excluded_tables = %w[admin_settings api_keys]

  # Authentication lambda - receives the controller instance
  # Example: config.authentication = ->(controller) { controller.current_user&.admin? }
  # config.authentication = ->(controller) { true }

  # Optional: Use a separate read-only database connection
  # config.read_only_connection = ActiveRecord::Base.connected_to(role: :reading) { ActiveRecord::Base.connection }
end
