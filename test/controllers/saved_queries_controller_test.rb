require "test_helper"

class QueryLens::SavedQueriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_query_lens_tables!
    QueryLens::SavedQuery.delete_all
    QueryLens::Project.delete_all
  end

  test "create saves a query without project" do
    post query_lens.saved_queries_path, params: { name: "User count", sql: "SELECT COUNT(*) FROM users" }, as: :json
    assert_response :created

    data = JSON.parse(response.body)
    assert_equal "User count", data["name"]
    assert_equal "SELECT COUNT(*) FROM users", data["sql"]
    assert_nil data["project_id"]
  end

  test "create saves a query with project" do
    project = QueryLens::Project.create!(name: "Analytics")
    post query_lens.saved_queries_path,
      params: { name: "User count", sql: "SELECT COUNT(*) FROM users", project_id: project.id },
      as: :json
    assert_response :created

    data = JSON.parse(response.body)
    assert_equal project.id, data["project_id"]
  end

  test "create rejects blank name" do
    post query_lens.saved_queries_path, params: { name: "", sql: "SELECT 1" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["errors"], "Name can't be blank"
  end

  test "create rejects blank sql" do
    post query_lens.saved_queries_path, params: { name: "Test", sql: "" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["errors"], "Sql can't be blank"
  end

  test "update modifies a query" do
    query = QueryLens::SavedQuery.create!(name: "Old", sql: "SELECT 1")
    patch query_lens.saved_query_path(query),
      params: { name: "New Name", sql: "SELECT 2", description: "Updated" },
      as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal "New Name", data["name"]
    assert_equal "SELECT 2", data["sql"]
    assert_equal "Updated", data["description"]
  end

  test "update can move query to a project" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Test", sql: "SELECT 1")

    patch query_lens.saved_query_path(query), params: { project_id: project.id }, as: :json
    assert_response :success

    assert_equal project.id, query.reload.project_id
  end

  test "update can move query to unorganized" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Test", sql: "SELECT 1", project: project)

    patch query_lens.saved_query_path(query), params: { project_id: "" }, as: :json
    assert_response :success

    assert_nil query.reload.project_id
  end

  test "destroy deletes a query" do
    query = QueryLens::SavedQuery.create!(name: "Test", sql: "SELECT 1")

    delete query_lens.saved_query_path(query), as: :json
    assert_response :no_content

    assert_nil QueryLens::SavedQuery.find_by(id: query.id)
  end

  test "authentication blocks unauthorized access" do
    QueryLens.configure { |c| c.authentication = ->(controller) { false } }

    post query_lens.saved_queries_path, params: { name: "Test", sql: "SELECT 1" }, as: :json
    assert_response :unauthorized
  end
end
