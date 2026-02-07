module QueryLens
  class Configuration
    attr_accessor :model, :max_rows, :query_timeout,
                  :excluded_tables, :authentication, :read_only_connection,
                  :schema_cache_ttl, :table_selection_threshold

    def initialize
      @model = "claude-sonnet-4-5-20250929"
      @max_rows = 1000
      @query_timeout = 30
      @excluded_tables = []
      @authentication = ->(controller) { true }
      @read_only_connection = nil
      @schema_cache_ttl = 300 # 5 minutes
      @table_selection_threshold = 50 # tables above this trigger two-stage generation
    end
  end
end
