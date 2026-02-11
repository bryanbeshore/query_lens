module QueryLens
  class Engine < ::Rails::Engine
    isolate_namespace QueryLens

    initializer "query_lens.assets" do |app|
      app.config.assets.precompile += %w[query_lens/application.js] if app.config.respond_to?(:assets)
    end
  end
end
