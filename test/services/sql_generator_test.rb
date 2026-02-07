require "test_helper"

class QueryLens::SqlGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = QueryLens::SqlGenerator.new(
      schema_prompt: "users (id, name, email)\naccounts (id, name, plan)"
    )
  end

  test "generates SQL from API response" do
    stub_llm_response(
      "Here's a query to count users.\n\n```sql\nSELECT COUNT(*) AS total_users FROM users\n```"
    )

    result = @generator.generate(messages: [{ role: "user", content: "How many users?" }])

    assert_equal "SELECT COUNT(*) AS total_users FROM users", result[:sql]
    assert_includes result[:explanation], "count users"
  end

  test "extracts SQL from code fences" do
    stub_llm_response(
      "Some explanation.\n\n```sql\nSELECT * FROM accounts WHERE plan = 'pro'\n```\n\nMore text."
    )

    result = @generator.generate(messages: [{ role: "user", content: "Show pro accounts" }])

    assert_equal "SELECT * FROM accounts WHERE plan = 'pro'", result[:sql]
  end

  test "returns nil sql when no code fences in response" do
    stub_llm_response("I'm not sure how to answer that question.")

    result = @generator.generate(messages: [{ role: "user", content: "What is love?" }])

    assert_nil result[:sql]
    assert_includes result[:explanation], "not sure"
  end

  test "passes conversation history to the model" do
    stub_llm_response(
      "Broken down by month.\n\n```sql\nSELECT DATE_TRUNC('month', created_at) AS month, COUNT(*) FROM users GROUP BY 1\n```"
    )

    messages = [
      { role: "user", content: "How many users?" },
      { role: "assistant", content: "```sql\nSELECT COUNT(*) FROM users\n```" },
      { role: "user", content: "Break that down by month" }
    ]

    result = @generator.generate(messages: messages)
    assert_includes result[:sql], "GROUP BY"
  end

  private

  def stub_llm_response(text)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          id: "msg_test",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: text }],
          model: "claude-sonnet-4-5-20250929",
          stop_reason: "end_turn",
          usage: { input_tokens: 100, output_tokens: 50 }
        }.to_json
      )
  end
end
