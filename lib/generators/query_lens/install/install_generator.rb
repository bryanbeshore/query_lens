module QueryLens
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a QueryLens initializer and adds the engine route."

      def copy_initializer
        template "initializer.rb", "config/initializers/query_lens.rb"
      end

      def add_route
        route 'mount QueryLens::Engine => "/query_lens"'
      end

      def show_post_install
        say ""
        say "QueryLens installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Set your ANTHROPIC_API_KEY environment variable"
        say "  2. Visit /query_lens in your browser"
        say ""
      end
    end
  end
end
