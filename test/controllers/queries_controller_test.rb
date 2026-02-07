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

  test "execute rejects multi-statement queries with semicolons" do
    post query_lens.execute_path, params: { sql: "SELECT 1; SELECT 2" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_equal "Multiple statements are not allowed", data["error"]
  end

  test "execute rejects TRUNCATE statements" do
    post query_lens.execute_path, params: { sql: "TRUNCATE users" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute rejects EXECUTE statements" do
    post query_lens.execute_path, params: { sql: "SELECT 1 WHERE EXECUTE something" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute rejects pg_sleep" do
    post query_lens.execute_path, params: { sql: "SELECT pg_sleep(3600)" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_equal "This function is not allowed", data["error"]
  end

  test "execute rejects pg_terminate_backend" do
    post query_lens.execute_path, params: { sql: "SELECT pg_terminate_backend(1234)" }, as: :json
    assert_response :unprocessable_entity
  end

  test "execute allows trailing semicolon" do
    post query_lens.execute_path, params: { sql: "SELECT name FROM users ORDER BY name;" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 2, data["row_count"]
  end

  test "execute allows WITH (CTE) queries" do
    post query_lens.execute_path, params: { sql: "WITH counts AS (SELECT COUNT(*) AS c FROM users) SELECT c FROM counts" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 1, data["row_count"]
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

  # ── Excluded table enforcement ──

  test "execute blocks queries against excluded tables" do
    QueryLens.configure { |c| c.excluded_tables = %w[users] }

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["error"], "restricted"
    assert_includes data["error"], "users"
  end

  test "execute blocks excluded tables in JOINs" do
    QueryLens.configure { |c| c.excluded_tables = %w[users] }

    post query_lens.execute_path,
      params: { sql: "SELECT a.id FROM accounts a JOIN users u ON u.id = a.user_id" },
      as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["error"], "users"
  end

  test "execute allows queries when excluded tables are not referenced" do
    QueryLens.configure { |c| c.excluded_tables = %w[api_keys secrets] }

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :success
  end

  # ── Info endpoint ──

  test "info returns excluded tables and config" do
    QueryLens.configure do |c|
      c.excluded_tables = %w[api_keys secrets]
      c.max_rows = 500
      c.query_timeout = 15
    end

    get query_lens.info_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal %w[api_keys secrets], data["excluded_tables"]
    assert_equal 500, data["max_rows"]
    assert_equal 15, data["query_timeout"]
  end

  test "info returns empty excluded tables when none configured" do
    get query_lens.info_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal [], data["excluded_tables"]
  end

  # ── Audit logging ──

  test "audit logger is called on successful query execution" do
    audit_entries = []
    QueryLens.configure do |c|
      c.audit_logger = ->(entry) { audit_entries << entry }
    end

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :success

    assert_equal 1, audit_entries.length
    assert_equal "execute", audit_entries[0][:action]
    assert_equal "SELECT * FROM users", audit_entries[0][:sql]
    assert_equal 2, audit_entries[0][:row_count]
    assert_nil audit_entries[0][:error]
    assert audit_entries[0][:timestamp].present?
    assert audit_entries[0][:ip].present?
  end

  test "audit logger is called on blocked queries" do
    audit_entries = []
    QueryLens.configure do |c|
      c.audit_logger = ->(entry) { audit_entries << entry }
    end

    post query_lens.execute_path, params: { sql: "DELETE FROM users" }, as: :json
    assert_response :unprocessable_entity

    assert_equal 1, audit_entries.length
    assert_equal "execute_blocked", audit_entries[0][:action]
  end

  test "audit logger is called when excluded table is blocked" do
    audit_entries = []
    QueryLens.configure do |c|
      c.excluded_tables = %w[users]
      c.audit_logger = ->(entry) { audit_entries << entry }
    end

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :unprocessable_entity

    assert_equal 1, audit_entries.length
    assert_equal "execute_blocked", audit_entries[0][:action]
    assert_includes audit_entries[0][:error], "Restricted table"
  end

  test "audit logger failure does not break query execution" do
    QueryLens.configure do |c|
      c.audit_logger = ->(entry) { raise "Audit DB down!" }
    end

    post query_lens.execute_path, params: { sql: "SELECT * FROM users" }, as: :json
    assert_response :success
  end
end
