# Configure RubyLLM with your AI provider(s).
# You only need keys for providers you plan to use.
# See https://rubyllm.com for full configuration options.
RubyLLM.configure do |config|
  # config.openai_api_key = ENV["OPENAI_API_KEY"]
  # config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  # config.gemini_api_key = ENV["GEMINI_API_KEY"]
  # config.deepseek_api_key = ENV["DEEPSEEK_API_KEY"]
  # config.ollama_api_base = "http://localhost:11434"  # For local models
end

QueryLens.configure do |config|
  # AI model to use (default: "claude-sonnet-4-5-20250929")
  # Any model supported by RubyLLM works: GPT, Claude, Gemini, Llama, etc.
  # config.model = "claude-sonnet-4-5-20250929"
  # config.model = "gpt-4o"
  # config.model = "gemini-2.0-flash"
  # config.model = "llama3.2"  # via Ollama

  # Maximum rows returned per query (default: 1000)
  # config.max_rows = 1000

  # Query timeout in seconds (default: 30)
  # config.query_timeout = 30

  # Tables to exclude from AI context AND block from query execution.
  # Users will see these listed as "restricted" in the UI.
  # config.excluded_tables = %w[admin_settings api_keys]

  # Authentication lambda - receives the controller instance
  # Example: config.authentication = ->(controller) { controller.current_user&.admin? }
  # config.authentication = ->(controller) { true }

  # Schema cache TTL in seconds (default: 300 / 5 minutes)
  # Avoids re-querying the database schema on every AI request.
  # config.schema_cache_ttl = 300

  # Table selection threshold (default: 50)
  # Schemas with more tables than this use a two-stage AI approach:
  # first selecting relevant tables, then generating SQL with only those tables.
  # This keeps token usage manageable for large databases.
  # config.table_selection_threshold = 50

  # Audit logging - receives a hash with :user, :action, :sql, :row_count, :error, :timestamp, :ip
  # config.audit_logger = ->(entry) { Rails.logger.info("[QueryLens Audit] #{entry}") }
  #
  # Example: log to a database table
  # config.audit_logger = ->(entry) {
  #   QueryAuditLog.create!(
  #     user_email: entry[:user],
  #     action: entry[:action],
  #     sql_query: entry[:sql],
  #     row_count: entry[:row_count],
  #     error_message: entry[:error],
  #     ip_address: entry[:ip]
  #   )
  # }

  # Method name to call on the controller to identify the current user (default: :current_user)
  # config.current_user_method = :current_user

  # Optional: Use a separate read-only database connection
  # config.read_only_connection = ActiveRecord::Base.connected_to(role: :reading) { ActiveRecord::Base.connection }
end
