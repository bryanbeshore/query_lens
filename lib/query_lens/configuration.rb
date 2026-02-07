module QueryLens
  class Configuration
    attr_accessor :model, :max_rows, :query_timeout,
                  :excluded_tables, :authentication, :read_only_connection,
                  :schema_cache_ttl, :table_selection_threshold,
                  :audit_logger, :current_user_method

    def initialize
      @model = "claude-sonnet-4-5-20250929"
      @max_rows = 1000
      @query_timeout = 30
      @excluded_tables = []
      @authentication = ->(controller) { true }
      @read_only_connection = nil
      @schema_cache_ttl = 300 # 5 minutes
      @table_selection_threshold = 50 # tables above this trigger two-stage generation
      @audit_logger = nil # lambda receiving { user:, action:, sql:, row_count:, error:, timestamp: }
      @current_user_method = :current_user # method name to call on controller to identify the user
    end
  end
end
