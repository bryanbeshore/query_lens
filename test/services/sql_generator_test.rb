require "test_helper"

class QueryLens::SqlGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = QueryLens::SqlGenerator.new(
      schema_prompt: "users (id, name, email)\naccounts (id, name, plan)"
    )
  end

  test "generates SQL from Claude API response" do
    stub_anthropic_response(
      "Here's a query to count users.\n\n```sql\nSELECT COUNT(*) AS total_users FROM users\n```"
    )

    result = @generator.generate(messages: [{ role: "user", content: "How many users?" }])

    assert_equal "SELECT COUNT(*) AS total_users FROM users", result[:sql]
    assert_includes result[:explanation], "count users"
  end

  test "extracts SQL from code fences" do
    stub_anthropic_response(
      "Some explanation.\n\n```sql\nSELECT * FROM accounts WHERE plan = 'pro'\n```\n\nMore text."
    )

    result = @generator.generate(messages: [{ role: "user", content: "Show pro accounts" }])

    assert_equal "SELECT * FROM accounts WHERE plan = 'pro'", result[:sql]
  end

  test "returns nil sql when no code fences in response" do
    stub_anthropic_response("I'm not sure how to answer that question.")

    result = @generator.generate(messages: [{ role: "user", content: "What is love?" }])

    assert_nil result[:sql]
    assert_includes result[:explanation], "not sure"
  end

  test "raises error when API key is not configured" do
    QueryLens.configure { |c| c.anthropic_api_key = nil }
    generator = QueryLens::SqlGenerator.new(schema_prompt: "test")

    assert_raises(RuntimeError, "Anthropic API key not configured") do
      generator.generate(messages: [{ role: "user", content: "test" }])
    end
  end

  private

  def stub_anthropic_response(text)
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
          usage: { input_tokens: 100, output_tokens: 50 }
        }.to_json
      )
  end
end
