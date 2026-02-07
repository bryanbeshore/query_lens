require "test_helper"

class QueryLens::SavedQueryTest < ActiveSupport::TestCase
  setup do
    create_query_lens_tables!
    QueryLens::SavedQuery.delete_all
    QueryLens::Project.delete_all
  end

  test "valid saved query saves successfully" do
    query = QueryLens::SavedQuery.new(name: "User count", sql: "SELECT COUNT(*) FROM users")
    assert query.save
    assert query.persisted?
  end

  test "requires name" do
    query = QueryLens::SavedQuery.new(name: nil, sql: "SELECT 1")
    assert_not query.valid?
    assert_includes query.errors[:name], "can't be blank"
  end

  test "requires sql" do
    query = QueryLens::SavedQuery.new(name: "Test", sql: nil)
    assert_not query.valid?
    assert_includes query.errors[:sql], "can't be blank"
  end

  test "name must be unique within same project" do
    project = QueryLens::Project.create!(name: "Analytics")
    QueryLens::SavedQuery.create!(name: "User count", sql: "SELECT COUNT(*) FROM users", project: project)

    duplicate = QueryLens::SavedQuery.new(name: "User count", sql: "SELECT 1", project: project)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "same name allowed in different projects" do
    project1 = QueryLens::Project.create!(name: "Analytics")
    project2 = QueryLens::Project.create!(name: "Finance")

    QueryLens::SavedQuery.create!(name: "Count", sql: "SELECT COUNT(*) FROM users", project: project1)
    q2 = QueryLens::SavedQuery.new(name: "Count", sql: "SELECT COUNT(*) FROM accounts", project: project2)
    assert q2.valid?
    assert q2.save
  end

  test "project is optional" do
    query = QueryLens::SavedQuery.new(name: "Standalone", sql: "SELECT 1")
    assert query.valid?
    assert_nil query.project_id
  end

  test "belongs_to project" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Test", sql: "SELECT 1", project: project)
    assert_equal project, query.project
  end

  test "default scope orders by position then name" do
    c = QueryLens::SavedQuery.create!(name: "C Query", sql: "SELECT 3", position: 2)
    a = QueryLens::SavedQuery.create!(name: "A Query", sql: "SELECT 1", position: 1)
    b = QueryLens::SavedQuery.create!(name: "B Query", sql: "SELECT 2", position: 1)

    queries = QueryLens::SavedQuery.all.to_a
    assert_equal [a, b, c], queries
  end
end
