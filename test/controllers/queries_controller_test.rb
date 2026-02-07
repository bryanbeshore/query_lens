require "test_helper"

class QueryLens::QueriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
        t.string :email
        t.timestamps
      end
    end

    ActiveRecord::Base.connection.execute("INSERT INTO users (name, email, created_at, updated_at) VALUES ('Alice', 'alice@example.com', datetime('now'), datetime('now'))")
    ActiveRecord::Base.connection.execute("INSERT INTO users (name, email, created_at, updated_at) VALUES ('Bob', 'bob@example.com', datetime('now'), datetime('now'))")
  end

  test "show renders the main UI" do
    get query_lens.root_path
    assert_response :success
    assert_includes response.body, "QueryLens"
  end

  test "execute runs SELECT queries" do
    post query_lens.execute_path, params: { sql: "SELECT name, email FROM users ORDER BY name" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal %w[name email], data["columns"]
    assert_equal 2, data["row_count"]
    assert_equal "Alice", data["rows"][0][0]
  end

  test "execute rejects non-SELECT queries" do
    post query_lens.execute_path, params: { sql: "DELETE FROM users" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_equal "Only SELECT queries are allowed", data["error"]
  end

  test "execute rejects INSERT statements" do
    post query_lens.execute_path, params: { sql: "INSERT INTO users (name) VALUES ('hacker')" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute rejects UPDATE statements" do
    post query_lens.execute_path, params: { sql: "UPDATE users SET name = 'hacked'" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute rejects DROP statements" do
    post query_lens.execute_path, params: { sql: "DROP TABLE users" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute rejects SELECT with embedded DELETE" do
    post query_lens.execute_path, params: { sql: "SELECT 1; DELETE FROM users" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute handles SQL errors gracefully" do
    post query_lens.execute_path, params: { sql: "SELECT * FROM nonexistent_table" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert data["error"].present?
  end

  test "execute respects max_rows configuration" do
    QueryLens.configure { |c| c.max_rows = 1 }

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 1, data["row_count"]
    assert_equal true, data["truncated"]
  end

  test "authentication blocks unauthorized access" do
    QueryLens.configure do |c|
      c.authentication = ->(controller) { false }
    end

    get query_lens.root_path
    assert_response :unauthorized
  end
end
