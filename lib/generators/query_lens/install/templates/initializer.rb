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

  # Tables to exclude from AI schema context
  # config.excluded_tables = %w[admin_settings api_keys]

  # Authentication lambda - receives the controller instance
  # Example: config.authentication = ->(controller) { controller.current_user&.admin? }
  # config.authentication = ->(controller) { true }

  # Optional: Use a separate read-only database connection
  # config.read_only_connection = ActiveRecord::Base.connected_to(role: :reading) { ActiveRecord::Base.connection }
end
