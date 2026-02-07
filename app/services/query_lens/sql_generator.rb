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

    TABLE_SELECTION_PROMPT = <<~PROMPT
      You are a database schema analyst. Given a list of tables and a user's question, identify which tables are needed to answer the question.

      RULES:
      - Return ONLY a comma-separated list of table names, nothing else.
      - Include tables needed for JOINs even if not directly mentioned.
      - When in doubt, include the table — it's better to include an extra table than miss one.
      - Typically 3-10 tables are relevant for a query.

      TABLES:
      %{compact_index}
    PROMPT

    def initialize(schema:, model: nil)
      @schema = schema
      @model = model || QueryLens.configuration.model
    end

    def generate(messages:)
      threshold = QueryLens.configuration.table_selection_threshold

      if @schema.length > threshold
        generate_two_stage(messages)
      else
        result = generate_single_stage(messages, SchemaIntrospector.new.format_schema(@schema))
        result.merge(
          strategy: "single_stage",
          total_tables: @schema.length,
          tables_used: @schema.length
        )
      end
    end

    private

    def generate_single_stage(messages, schema_prompt)
      system = SYSTEM_PROMPT % {
        schema: schema_prompt,
        max_rows: QueryLens.configuration.max_rows
      }

      chat = RubyLLM.chat(model: @model)
      chat.with_instructions(system)

      history = normalize_messages(messages)
      replay_history(chat, history)

      last = history.last
      response = chat.ask(last[:content])
      content = response.content.to_s

      sql = extract_sql(content)
      { explanation: extract_explanation(content), sql: sql, raw: content }
    end

    def generate_two_stage(messages)
      # Stage 1: Ask LLM to pick relevant tables from compact index
      compact_index = SchemaIntrospector.compact_index(@schema)
      selection_system = TABLE_SELECTION_PROMPT % { compact_index: compact_index }

      selector = RubyLLM.chat(model: @model)
      selector.with_instructions(selection_system)

      # Build the question from the latest user message
      history = normalize_messages(messages)
      question = history.select { |m| m[:role] == :user }.last&.dig(:content) || history.last[:content]

      selection_response = selector.ask(question)
      selected_names = selection_response.content.to_s
        .split(",")
        .map(&:strip)
        .reject(&:empty?)

      # Always include tables that were mentioned in the conversation
      all_table_names = @schema.map { |t| t[:name] }
      conversation_text = history.map { |m| m[:content] }.join(" ").downcase
      mentioned = all_table_names.select { |t| conversation_text.include?(t.downcase) }

      relevant_tables = (selected_names + mentioned).uniq & all_table_names

      # Fallback: if selection returned nothing usable, send full schema
      if relevant_tables.empty?
        result = generate_single_stage(messages, SchemaIntrospector.new.format_schema(@schema))
        return result.merge(
          strategy: "two_stage_fallback",
          total_tables: @schema.length,
          tables_used: @schema.length,
          tables_selected: all_table_names
        )
      end

      # Stage 2: Generate SQL with full schema of selected tables only
      filtered_prompt = SchemaIntrospector.prompt_for_tables(@schema, relevant_tables)
      result = generate_single_stage(messages, filtered_prompt)
      result.merge(
        strategy: "two_stage",
        total_tables: @schema.length,
        tables_used: relevant_tables.length,
        tables_selected: relevant_tables
      )
    end

    def normalize_messages(messages)
      history = messages.is_a?(Array) ? messages.map(&:symbolize_keys) : []
      history.map { |m| { role: m[:role].to_sym, content: m[:content] } }
    end

    def replay_history(chat, history)
      history[0..-2].each do |msg|
        chat.add_message(role: msg[:role], content: msg[:content])
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
