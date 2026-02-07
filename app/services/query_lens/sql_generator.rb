require "anthropic"

module QueryLens
  class SqlGenerator
    SYSTEM_PROMPT = <<~PROMPT
      You are a SQL query generator. You help users explore their database by converting natural language questions into SQL queries.

      RULES:
      - ONLY generate SELECT statements. Never generate INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, or any other data-modifying statements.
      - Always use clear column aliases for readability (e.g., "total_amount" instead of "sum(amount)").
      - Limit results to %{max_rows} rows by default unless the user asks for more or fewer.
      - Use table aliases for readability in joins.
      - When asked to "break down by" something, use GROUP BY.
      - Format large numbers readably when possible.
      - If the user's question is ambiguous, make reasonable assumptions and explain them.
      - Always include an ORDER BY clause when it makes sense (e.g., by date descending, by amount descending).

      RESPONSE FORMAT:
      Respond with a brief explanation of what the query does, then the SQL query wrapped in ```sql code fences.
      Keep explanations concise (1-2 sentences).

      DATABASE SCHEMA:
      %{schema}
    PROMPT

    def initialize(schema_prompt:, api_key: nil, model: nil)
      @schema_prompt = schema_prompt
      @api_key = api_key || QueryLens.configuration.anthropic_api_key
      @model = model || QueryLens.configuration.model
    end

    def generate(messages:)
      raise "Anthropic API key not configured" unless @api_key

      client = Anthropic::Client.new(api_key: @api_key)

      system = SYSTEM_PROMPT % {
        schema: @schema_prompt,
        max_rows: QueryLens.configuration.max_rows
      }

      response = client.messages.create(
        model: @model,
        max_tokens: 2048,
        system: system,
        messages: messages
      )

      content = extract_text(response)
      sql = extract_sql(content)

      { explanation: extract_explanation(content), sql: sql, raw: content }
    end

    private

    def extract_text(response)
      if response.respond_to?(:content)
        block = response.content&.first
        block.respond_to?(:text) ? block.text.to_s : ""
      elsif response.is_a?(Hash)
        response.dig("content", 0, "text") || response.dig(:content, 0, :text) || ""
      else
        ""
      end
    end

    def extract_sql(content)
      match = content.match(/```sql\s*\n?(.*?)\n?```/m)
      match ? match[1].strip : nil
    end

    def extract_explanation(content)
      content.sub(/```sql.*?```/m, "").strip
    end
  end
end
