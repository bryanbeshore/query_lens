module QueryLens
  class Configuration
    attr_accessor :anthropic_api_key, :model, :max_rows, :query_timeout,
                  :excluded_tables, :authentication, :read_only_connection

    def initialize
      @anthropic_api_key = nil
      @model = "claude-sonnet-4-5-20250929"
      @max_rows = 1000
      @query_timeout = 30
      @excluded_tables = []
      @authentication = ->(controller) { true }
      @read_only_connection = nil
    end
  end
end
