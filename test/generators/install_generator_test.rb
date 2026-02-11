require "test_helper"
require "generators/query_lens/install/install_generator"

class QueryLens::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests QueryLens::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  setup do
    prepare_destination
    create_empty_routes_file
  end

  test "copies initializer" do
    run_generator
    assert_file "config/initializers/query_lens.rb"
  end

  test "adds engine route" do
    run_generator
    assert_file "config/routes.rb" do |content|
      assert_match(/mount QueryLens::Engine/, content)
    end
  end

  test "creates migration file" do
    run_generator
    assert_migration "db/migrate/create_query_lens_tables.rb"
  end

  test "migration inherits from versioned ActiveRecord::Migration" do
    run_generator
    assert_migration "db/migrate/create_query_lens_tables.rb" do |content|
      version = ActiveRecord::Migration.current_version
      assert_match(/< ActiveRecord::Migration\[#{version}\]/, content)
    end
  end

  test "migration creates all query_lens tables" do
    run_generator
    assert_migration "db/migrate/create_query_lens_tables.rb" do |content|
      assert_match(/create_table :query_lens_projects/, content)
      assert_match(/create_table :query_lens_saved_queries/, content)
      assert_match(/create_table :query_lens_conversations/, content)
    end
  end

  private

  def create_empty_routes_file
    routes_dir = File.join(destination_root, "config")
    FileUtils.mkdir_p(routes_dir)
    File.write(File.join(routes_dir, "routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY
  end
end
