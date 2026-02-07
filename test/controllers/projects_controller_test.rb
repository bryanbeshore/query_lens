require "test_helper"

class QueryLens::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_query_lens_tables!
    QueryLens::SavedQuery.delete_all
    QueryLens::Project.delete_all
  end

  test "index returns projects with nested queries and unorganized queries" do
    project = QueryLens::Project.create!(name: "Analytics")
    QueryLens::SavedQuery.create!(name: "Users", sql: "SELECT * FROM users", project: project)
    QueryLens::SavedQuery.create!(name: "Standalone", sql: "SELECT 1")

    get query_lens.projects_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 1, data["projects"].length
    assert_equal "Analytics", data["projects"][0]["name"]
    assert_equal 1, data["projects"][0]["saved_queries"].length
    assert_equal "Users", data["projects"][0]["saved_queries"][0]["name"]
    assert_equal 1, data["unorganized"].length
    assert_equal "Standalone", data["unorganized"][0]["name"]
  end

  test "index returns empty tree" do
    get query_lens.projects_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal [], data["projects"]
    assert_equal [], data["unorganized"]
  end

  test "create creates a project" do
    post query_lens.projects_path, params: { name: "Rewards" }, as: :json
    assert_response :created

    data = JSON.parse(response.body)
    assert_equal "Rewards", data["name"]
    assert QueryLens::Project.find_by(name: "Rewards")
  end

  test "create rejects blank name" do
    post query_lens.projects_path, params: { name: "" }, as: :json
    assert_response :unprocessable_entity

    data = JSON.parse(response.body)
    assert_includes data["errors"], "Name can't be blank"
  end

  test "create rejects duplicate name" do
    QueryLens::Project.create!(name: "Analytics")
    post query_lens.projects_path, params: { name: "Analytics" }, as: :json
    assert_response :unprocessable_entity
  end

  test "update renames a project" do
    project = QueryLens::Project.create!(name: "Old Name")
    patch query_lens.project_path(project), params: { name: "New Name" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal "New Name", data["name"]
    assert_equal "New Name", project.reload.name
  end

  test "update rejects blank name" do
    project = QueryLens::Project.create!(name: "Analytics")
    patch query_lens.project_path(project), params: { name: "" }, as: :json
    assert_response :unprocessable_entity
  end

  test "destroy deletes a project and nullifies queries" do
    project = QueryLens::Project.create!(name: "Analytics")
    query = QueryLens::SavedQuery.create!(name: "Test", sql: "SELECT 1", project: project)

    delete query_lens.project_path(project), as: :json
    assert_response :no_content

    assert_nil QueryLens::Project.find_by(id: project.id)
    assert_nil query.reload.project_id
  end

  test "authentication blocks unauthorized access" do
    QueryLens.configure { |c| c.authentication = ->(controller) { false } }

    get query_lens.projects_path, as: :json
    assert_response :unauthorized
  end
end
