module QueryLens
  class SchemaIntrospector
    EXCLUDED_TABLES = %w[
      schema_migrations
      ar_internal_metadata
      solid_queue_blocked_executions
      solid_queue_claimed_executions
      solid_queue_failed_executions
      solid_queue_jobs
      solid_queue_pauses
      solid_queue_processes
      solid_queue_ready_executions
      solid_queue_recurring_executions
      solid_queue_recurring_tasks
      solid_queue_scheduled_executions
      solid_queue_semaphores
      solid_cache_entries
      solid_cable_messages
      query_lens_projects
      query_lens_saved_queries
      query_lens_conversations
    ].freeze

    # Schema cache: keyed by source, stores { schema: [...], generated_at: Time }
    @caches = {}
    @cache_mutex = Mutex.new

    class << self
      def cached_schema(connection: nil, ttl: nil, source: "activerecord")
        ttl ||= QueryLens.configuration.schema_cache_ttl

        @cache_mutex.synchronize do
          cached = @caches[source]
          if cached && (Time.now - cached[:generated_at]) < ttl
            return cached[:schema]
          end

          schema = new(connection: connection, source: source).introspect
          @caches[source] = { schema: schema, generated_at: Time.now }
          schema
        end
      end

      def clear_cache!
        @cache_mutex.synchronize { @caches = {} }
      end
    end

    def initialize(connection: nil, source: "activerecord")
      @connection = connection || ActiveRecord::Base.connection
      @source = source
    end

    def introspect
      if @source == "snowflake" && QueryLens.configuration.snowflake?
        introspect_snowflake
      else
        tables = @connection.tables - EXCLUDED_TABLES - QueryLens.configuration.excluded_tables
        tables.sort.map { |table| introspect_table(table) }
      end
    end

    # Full schema prompt (all tables) — used for small schemas
    def to_prompt
      format_schema(introspect)
    end

    # Compact index: one line per table with column names, for table selection stage
    def self.compact_index(schema)
      lines = ["Tables in this database:", ""]
      schema.each do |table|
        col_names = table[:columns].map { |c| c[:name] }.join(", ")
        lines << "#{table[:name]} (#{col_names}) ~#{table[:approximate_row_count]} rows"
      end
      lines.join("\n")
    end

    # Full schema prompt for only the specified tables
    def self.prompt_for_tables(schema, table_names)
      selected = schema.select { |t| table_names.include?(t[:name]) }
      return "No matching tables found." if selected.empty?

      new.format_schema(selected)
    end

    def format_schema(tables)
      lines = ["Database Schema:", ""]

      tables.each do |table|
        lines << "#{table[:name]} (~#{table[:approximate_row_count]} rows)"
        table[:columns].each do |col|
          parts = ["  #{col[:name]}: #{col[:type]}"]
          parts << "NOT NULL" unless col[:null]
          parts << "PK" if col[:primary_key]
          parts << "DEFAULT #{col[:default]}" if col[:default]
          lines << parts.join(" ")
        end
        if table[:foreign_keys].any?
          table[:foreign_keys].each do |fk|
            lines << "  FK: #{fk[:column]} -> #{fk[:to_table]}.#{fk[:primary_key]}"
          end
        end
        lines << ""
      end

      lines.join("\n")
    end

    private

    def introspect_table(table)
      columns = @connection.columns(table).map do |col|
        {
          name: col.name,
          type: col.sql_type,
          null: col.null,
          default: col.default,
          primary_key: col.name == primary_key_for(table)
        }
      end

      foreign_keys = infer_foreign_keys(table, columns)
      row_count = approximate_row_count(table)

      {
        name: table,
        columns: columns,
        foreign_keys: foreign_keys,
        approximate_row_count: row_count
      }
    end

    def primary_key_for(table)
      @connection.primary_key(table)
    end

    def infer_foreign_keys(table, columns)
      fk_columns = columns.select { |c| c[:name].end_with?("_id") }
      all_tables = @connection.tables

      fk_columns.filter_map do |col|
        referenced_table = col[:name].sub(/_id$/, "").pluralize
        if all_tables.include?(referenced_table)
          { column: col[:name], to_table: referenced_table, primary_key: "id" }
        end
      end
    end

    def approximate_row_count(table)
      if @connection.adapter_name.downcase.include?("postgresql")
        result = @connection.select_value(
          "SELECT reltuples::bigint FROM pg_class WHERE relname = #{@connection.quote(table)}"
        )
        [result.to_i, 0].max
      else
        @connection.select_value("SELECT COUNT(*) FROM #{@connection.quote_table_name(table)}").to_i
      end
    rescue
      0
    end

    # Snowflake-specific introspection

    def introspect_snowflake
      config = QueryLens.configuration
      excluded = EXCLUDED_TABLES + config.excluded_tables

      tables = snowflake_query(
        "SELECT TABLE_NAME, ROW_COUNT FROM INFORMATION_SCHEMA.TABLES " \
        "WHERE TABLE_SCHEMA = '#{config.snowflake_schema}' AND TABLE_TYPE = 'BASE TABLE' " \
        "ORDER BY TABLE_NAME"
      )

      tables.filter_map do |row|
        table_name = row["TABLE_NAME"]
        next if excluded.include?(table_name.downcase)

        columns = snowflake_introspect_columns(table_name)
        pk_columns = snowflake_primary_keys(table_name)
        all_table_names = tables.map { |t| t["TABLE_NAME"].downcase }

        columns.each do |col|
          col[:primary_key] = pk_columns.include?(col[:name])
        end

        foreign_keys = snowflake_infer_foreign_keys(columns, all_table_names)

        {
          name: table_name,
          columns: columns,
          foreign_keys: foreign_keys,
          approximate_row_count: row["ROW_COUNT"].to_i
        }
      end
    end

    def snowflake_introspect_columns(table_name)
      config = QueryLens.configuration
      rows = snowflake_query(
        "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT " \
        "FROM INFORMATION_SCHEMA.COLUMNS " \
        "WHERE TABLE_SCHEMA = '#{config.snowflake_schema}' AND TABLE_NAME = '#{table_name}' " \
        "ORDER BY ORDINAL_POSITION"
      )

      rows.map do |row|
        {
          name: row["COLUMN_NAME"],
          type: row["DATA_TYPE"],
          null: row["IS_NULLABLE"] == "YES",
          default: row["COLUMN_DEFAULT"],
          primary_key: false
        }
      end
    end

    def snowflake_primary_keys(table_name)
      config = QueryLens.configuration
      rows = snowflake_query(
        "SELECT kcu.COLUMN_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc " \
        "JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu " \
        "ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME " \
        "AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA " \
        "AND tc.TABLE_NAME = kcu.TABLE_NAME " \
        "WHERE tc.TABLE_SCHEMA = '#{config.snowflake_schema}' " \
        "AND tc.TABLE_NAME = '#{table_name}' " \
        "AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'"
      )
      rows.map { |r| r["COLUMN_NAME"] }
    rescue
      []
    end

    def snowflake_infer_foreign_keys(columns, all_table_names)
      fk_columns = columns.select { |c| c[:name].downcase.end_with?("_id") }

      fk_columns.filter_map do |col|
        referenced_table = col[:name].downcase.sub(/_id$/, "").pluralize
        if all_table_names.include?(referenced_table)
          { column: col[:name], to_table: referenced_table.upcase, primary_key: "ID" }
        end
      end
    end

    def snowflake_query(sql)
      config = QueryLens.configuration
      result = config.snowflake_client.query(
        sql,
        warehouse: config.snowflake_warehouse,
        database: config.snowflake_database,
        schema: config.snowflake_schema,
        role: config.snowflake_role
      )
      result.map { |row| row.to_h.transform_keys(&:to_s) }
    end
  end
end
