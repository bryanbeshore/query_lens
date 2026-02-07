require "test_helper"

class QueryLens::AiControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
        t.string :email
        t.timestamps
      end
    end
  end

  test "generate returns SQL from Claude" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          id: "msg_test",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: "Count of all users.\n\n```sql\nSELECT COUNT(*) AS total FROM users\n```" }],
          model: "claude-sonnet-4-5-20250929",
          usage: { input_tokens: 100, output_tokens: 50 }
        }.to_json
      )

    post query_lens.generate_path,
      params: { messages: [{ role: "user", content: "How many users?" }] },
      as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal "SELECT COUNT(*) AS total FROM users", data["sql"]
    assert data["explanation"].present?
  end

  test "generate returns error when API fails" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: "Internal Server Error")

    post query_lens.generate_path,
      params: { messages: [{ role: "user", content: "test" }] },
      as: :json

    assert_response :unprocessable_entity
    data = JSON.parse(response.body)
    assert data["error"].present?
  end
end
