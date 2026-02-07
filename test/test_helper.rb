ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!

class ActiveSupport::TestCase
  setup do
    QueryLens.reset_configuration!
    QueryLens::SchemaIntrospector.clear_cache!
    RubyLLM.configure do |config|
      config.anthropic_api_key = "test-api-key"
    end
  end
end

def create_query_lens_tables!
  ActiveRecord::Schema.define do
    create_table :query_lens_projects, force: true do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.timestamps
    end

    add_index :query_lens_projects, :name, unique: true

    create_table :query_lens_saved_queries, force: true do |t|
      t.string :name, null: false
      t.text :description
      t.text :sql, null: false
      t.references :project, foreign_key: false
      t.integer :position
      t.timestamps
    end

    add_index :query_lens_saved_queries, [:project_id, :name], unique: true
  end
end
