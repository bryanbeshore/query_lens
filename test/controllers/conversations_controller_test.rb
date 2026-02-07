require "test_helper"

class QueryLens::ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_query_lens_tables!
    QueryLens::Conversation.delete_all
  end

  test "index returns conversations without messages" do
    QueryLens::Conversation.create!(
      title: "Test convo",
      messages: [{ "role" => "user", "content" => "How many users?" }],
      last_sql: "SELECT COUNT(*) FROM users"
    )

    get query_lens.conversations_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 1, data.length
    assert_equal "Test convo", data[0]["title"]
    assert data[0].key?("id")
    assert data[0].key?("updated_at")
    assert_not data[0].key?("messages")
    assert_not data[0].key?("last_sql")
  end

  test "index limits to 50 conversations" do
    55.times do |i|
      QueryLens::Conversation.create!(
        title: "Convo #{i}",
        messages: [{ "role" => "user", "content" => "msg #{i}" }]
      )
    end

    get query_lens.conversations_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 50, data.length
  end

  test "index returns conversations ordered by updated_at desc" do
    old = QueryLens::Conversation.create!(title: "Old", messages: [{ "role" => "user", "content" => "old" }])
    old.update_column(:updated_at, 2.hours.ago)
    new_convo = QueryLens::Conversation.create!(title: "New", messages: [{ "role" => "user", "content" => "new" }])

    get query_lens.conversations_path, as: :json
    data = JSON.parse(response.body)

    assert_equal new_convo.id, data[0]["id"]
    assert_equal old.id, data[1]["id"]
  end

  test "show returns full conversation with messages and last_sql" do
    convo = QueryLens::Conversation.create!(
      title: "Test",
      messages: [{ "role" => "user", "content" => "How many users?" }],
      last_sql: "SELECT COUNT(*) FROM users"
    )

    get query_lens.conversation_path(convo), as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal convo.id, data["id"]
    assert_equal "Test", data["title"]
    assert_equal 1, data["messages"].length
    assert_equal "SELECT COUNT(*) FROM users", data["last_sql"]
  end

  test "create persists a new conversation" do
    post query_lens.conversations_path,
      params: {
        title: "How many users?",
        messages: [{ role: "user", content: "How many users?" }],
        last_sql: "SELECT COUNT(*) FROM users"
      },
      as: :json
    assert_response :created

    data = JSON.parse(response.body)
    assert_equal "How many users?", data["title"]
    assert_equal 1, data["messages"].length
    assert_equal "SELECT COUNT(*) FROM users", data["last_sql"]
    assert data["id"].present?
  end

  test "create rejects blank title" do
    post query_lens.conversations_path,
      params: { title: "", messages: [{ role: "user", content: "test" }] },
      as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["errors"], "Title can't be blank"
  end

  test "create rejects empty messages" do
    post query_lens.conversations_path,
      params: { title: "Test", messages: [] },
      as: :json
    assert_response :unprocessable_entity
  end

  test "update modifies conversation" do
    convo = QueryLens::Conversation.create!(
      title: "Test",
      messages: [{ "role" => "user", "content" => "How many users?" }]
    )

    patch query_lens.conversation_path(convo),
      params: {
        messages: [
          { role: "user", content: "How many users?" },
          { role: "assistant", content: "Here is the SQL" }
        ],
        last_sql: "SELECT COUNT(*) FROM users"
      },
      as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 2, data["messages"].length
    assert_equal "SELECT COUNT(*) FROM users", data["last_sql"]
  end

  test "destroy deletes a conversation" do
    convo = QueryLens::Conversation.create!(
      title: "Test",
      messages: [{ "role" => "user", "content" => "test" }]
    )

    delete query_lens.conversation_path(convo), as: :json
    assert_response :no_content

    assert_nil QueryLens::Conversation.find_by(id: convo.id)
  end

  test "authentication blocks unauthorized access" do
    QueryLens.configure { |c| c.authentication = ->(controller) { false } }

    get query_lens.conversations_path, as: :json
    assert_response :unauthorized
  end
end
