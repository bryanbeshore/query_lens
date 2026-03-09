require "rails/generators/active_record/migration"

module QueryLens
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      desc "Creates a QueryLens initializer, copies migrations, and adds the engine route."

      def copy_initializer
        template "initializer.rb", "config/initializers/query_lens.rb"
      end

      def copy_migrations
        migration_template "create_query_lens_tables.rb.tt", "db/migrate/create_query_lens_tables.rb"
      end

      def add_route
        route 'mount QueryLens::Engine => "/query_lens"'
      end

      def show_post_install
        say ""
        say "QueryLens installed successfully!", :green
        if uuid?
          say "  Detected UUID primary keys — using UUID for all QueryLens tables.", :cyan
        end
        say ""
        say "Next steps:"
        say "  1. Run `rails db:migrate` to create QueryLens tables"
        say "  2. Set your ANTHROPIC_API_KEY environment variable"
        say "  3. Visit /query_lens in your browser"
        say ""
      end

      private

      def uuid?
        Rails.application.config.generators.options.dig(:active_record, :primary_key_type).to_s == "uuid"
      end
    end
  end
end
