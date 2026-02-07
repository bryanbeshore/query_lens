require "test_helper"

class QueryLens::ProjectTest < ActiveSupport::TestCase
  setup do
    create_query_lens_tables!
    QueryLens::SavedQuery.delete_all
    QueryLens::Project.delete_all
  end

  test "valid project saves successfully" do
    project = QueryLens::Project.new(name: "Analytics")
    assert project.save
    assert project.persisted?
  end

  test "requires name" do
    project = QueryLens::Project.new(name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "name must be unique" do
    QueryLens::Project.create!(name: "Analytics")
    duplicate = QueryLens::Project.new(name: "Analytics")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "has_many saved_queries" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Users count", sql: "SELECT COUNT(*) FROM users", project: project)
    assert_includes project.saved_queries.reload, query
  end

  test "destroying project nullifies saved queries" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Users count", sql: "SELECT COUNT(*) FROM users", project: project)

    project.destroy

    query.reload
    assert_nil query.project_id
    assert query.persisted?
  end

  test "default scope orders by position then name" do
    c = QueryLens::Project.create!(name: "C Project", position: 2)
    a = QueryLens::Project.create!(name: "A Project", position: 1)
    b = QueryLens::Project.create!(name: "B Project", position: 1)

    projects = QueryLens::Project.all.to_a
    assert_equal [a, b, c], projects
  end
end
