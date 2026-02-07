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

    def initialize(schema_prompt:, model: nil)
      @schema_prompt = schema_prompt
      @model = model || QueryLens.configuration.model
    end

    def generate(messages:)
      system = SYSTEM_PROMPT % {
        schema: @schema_prompt,
        max_rows: QueryLens.configuration.max_rows
      }

      chat = RubyLLM.chat(model: @model)
      chat.with_instructions(system)

      # Add all prior messages as context without making API calls
      history = messages.is_a?(Array) ? messages.map(&:symbolize_keys) : []
      history[0..-2].each do |msg|
        chat.add_message(role: msg[:role].to_sym, content: msg[:content])
      end

      # Send the final message which triggers the API call
      last = history.last
      response = chat.ask(last[:content])
      content = response.content.to_s

      sql = extract_sql(content)
      { explanation: extract_explanation(content), sql: sql, raw: content }
    end

    private

    def extract_sql(content)
      match = content.match(/```sql\s*\n?(.*?)\n?```/m)
      match ? match[1].strip : nil
    end

    def extract_explanation(content)
      content.sub(/```sql.*?```/m, "").strip
    end
  end
end
