module QueryLens
  class QueriesController < ApplicationController
    def show
    end

    def execute
      sql = params[:sql].to_s.strip

      # Layer 1: Must start with SELECT or WITH (for CTEs)
      unless sql.match?(/\A\s*(\(?\s*SELECT|WITH\s)/i)
        return render json: { error: "Only SELECT queries are allowed" }, status: :unprocessable_entity
      end

      # Layer 2: Block any DML/DDL keywords anywhere in the query
      if sql.match?(/\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE|EXEC|EXECUTE|CALL)\b/i)
        return render json: { error: "Only SELECT queries are allowed" }, status: :unprocessable_entity
      end

      # Layer 3: Block semicolons to prevent multi-statement injection
      if sql.include?(";")
        return render json: { error: "Multiple statements are not allowed" }, status: :unprocessable_entity
      end

      # Layer 4: Block dangerous PostgreSQL functions
      if sql.match?(/\b(pg_sleep|pg_terminate_backend|pg_cancel_backend|lo_import|lo_export|copy\s)/i)
        return render json: { error: "This function is not allowed" }, status: :unprocessable_entity
      end

      connection = QueryLens.configuration.read_only_connection || ActiveRecord::Base.connection
      postgresql = connection.adapter_name.downcase.include?("postgresql")
      timeout = QueryLens.configuration.query_timeout

      begin
        # Layer 5: Database-level read-only enforcement + timeout
        if postgresql
          connection.execute("BEGIN")
          connection.execute("SET TRANSACTION READ ONLY")
          connection.execute("SET LOCAL statement_timeout = '#{timeout.to_i * 1000}'")
        end

        result = connection.exec_query(sql)
        columns = result.columns
        rows = result.rows

        if postgresql
          connection.execute("ROLLBACK")
        end

        max_rows = QueryLens.configuration.max_rows
        truncated = rows.length > max_rows
        rows = rows.first(max_rows) if truncated

        render json: {
          columns: columns,
          rows: rows,
          row_count: rows.length,
          truncated: truncated
        }
      rescue => e
        connection.execute("ROLLBACK") if postgresql rescue nil
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
