module QueryLens
  class Engine < ::Rails::Engine
    isolate_namespace QueryLens

    initializer "query_lens.assets" do |app|
      app.config.assets.precompile += %w[query_lens/application.js] if app.config.respond_to?(:assets)
    end

    initializer "query_lens.migrations" do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
