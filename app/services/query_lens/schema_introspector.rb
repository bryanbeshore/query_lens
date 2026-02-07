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
    ].freeze

    def initialize(connection: nil)
      @connection = connection || ActiveRecord::Base.connection
    end

    def introspect
      tables = @connection.tables - EXCLUDED_TABLES - QueryLens.configuration.excluded_tables
      tables.sort.map { |table| introspect_table(table) }
    end

    def to_prompt
      schema = introspect
      lines = ["Database Schema:", ""]

      schema.each do |table|
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
  end
end
