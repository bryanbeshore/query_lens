module QueryLens
  class QueriesController < ApplicationController
    def show
    end

    def execute
      sql = params[:sql].to_s.strip

      unless sql.match?(/\A\s*(\(?\s*SELECT|WITH\s)/i)
        return render json: { error: "Only SELECT queries are allowed" }, status: :unprocessable_entity
      end

      if sql.match?(/\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE)\b/i)
        return render json: { error: "Only SELECT queries are allowed" }, status: :unprocessable_entity
      end

      connection = QueryLens.configuration.read_only_connection || ActiveRecord::Base.connection
      postgresql = connection.adapter_name.downcase.include?("postgresql")

      begin
        if postgresql
          connection.execute("BEGIN")
          connection.execute("SET TRANSACTION READ ONLY")
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
