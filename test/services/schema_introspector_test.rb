require "test_helper"

class QueryLens::SchemaIntrospectorTest < ActiveSupport::TestCase
  setup do
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name
        t.string :email
        t.timestamps
      end

      create_table :accounts, force: true do |t|
        t.string :name
        t.string :plan
        t.timestamps
      end

      create_table :transactions, force: true do |t|
        t.references :account
        t.references :user
        t.decimal :amount, precision: 10, scale: 2
        t.string :description
        t.timestamps
      end
    end

    @introspector = QueryLens::SchemaIntrospector.new
  end

  test "introspects all non-excluded tables" do
    schema = @introspector.introspect
    table_names = schema.map { |t| t[:name] }

    assert_includes table_names, "users"
    assert_includes table_names, "accounts"
    assert_includes table_names, "transactions"
    refute_includes table_names, "schema_migrations"
    refute_includes table_names, "ar_internal_metadata"
  end

  test "introspects columns with types" do
    schema = @introspector.introspect
    users_table = schema.find { |t| t[:name] == "users" }
    column_names = users_table[:columns].map { |c| c[:name] }

    assert_includes column_names, "id"
    assert_includes column_names, "name"
    assert_includes column_names, "email"
  end

  test "identifies foreign keys from _id columns" do
    schema = @introspector.introspect
    transactions_table = schema.find { |t| t[:name] == "transactions" }
    fk_tables = transactions_table[:foreign_keys].map { |fk| fk[:to_table] }

    assert_includes fk_tables, "accounts"
    assert_includes fk_tables, "users"
  end

  test "generates prompt text" do
    prompt = @introspector.to_prompt
    assert_includes prompt, "Database Schema:"
    assert_includes prompt, "users"
    assert_includes prompt, "accounts"
    assert_includes prompt, "transactions"
    assert_includes prompt, "account_id"
  end

  test "respects excluded_tables configuration" do
    QueryLens.configure { |c| c.excluded_tables = %w[transactions] }
    schema = @introspector.introspect
    table_names = schema.map { |t| t[:name] }

    refute_includes table_names, "transactions"
    assert_includes table_names, "users"
  end

  test "includes approximate row counts" do
    schema = @introspector.introspect
    users_table = schema.find { |t| t[:name] == "users" }
    assert_equal 0, users_table[:approximate_row_count]
  end

  # --- Caching tests ---

  test "cached_schema returns same data on repeated calls" do
    first = QueryLens::SchemaIntrospector.cached_schema
    second = QueryLens::SchemaIntrospector.cached_schema

    assert_equal first.map { |t| t[:name] }, second.map { |t| t[:name] }
  end

  test "cached_schema respects TTL" do
    QueryLens.configure { |c| c.schema_cache_ttl = 0.1 }

    first = QueryLens::SchemaIntrospector.cached_schema
    sleep 0.2
    # After TTL expires, it re-introspects (still returns valid data)
    second = QueryLens::SchemaIntrospector.cached_schema

    assert_equal first.map { |t| t[:name] }, second.map { |t| t[:name] }
  end

  test "clear_cache forces re-introspection" do
    QueryLens::SchemaIntrospector.cached_schema
    QueryLens::SchemaIntrospector.clear_cache!

    # Should work fine after clearing — just re-introspects
    result = QueryLens::SchemaIntrospector.cached_schema
    assert result.any?
  end

  # --- Compact index tests ---

  test "compact_index produces one line per table" do
    schema = @introspector.introspect
    index = QueryLens::SchemaIntrospector.compact_index(schema)

    assert_includes index, "Tables in this database:"
    assert_includes index, "users"
    assert_includes index, "accounts"
    assert_includes index, "transactions"
    # Each table should list its column names
    assert_includes index, "name, email"
    assert_includes index, "account_id"
  end

  # --- Filtered schema tests ---

  test "prompt_for_tables returns only selected tables" do
    schema = @introspector.introspect
    filtered = QueryLens::SchemaIntrospector.prompt_for_tables(schema, ["users"])

    assert_includes filtered, "users"
    refute_includes filtered, "accounts"
    refute_includes filtered, "transactions"
  end

  test "prompt_for_tables returns message when no tables match" do
    schema = @introspector.introspect
    result = QueryLens::SchemaIntrospector.prompt_for_tables(schema, ["nonexistent"])

    assert_equal "No matching tables found.", result
  end
end
