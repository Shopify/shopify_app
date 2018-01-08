module ShopifyApp
  class Engine < Rails::Engine
    engine_name 'shopify_app'
    isolate_namespace ShopifyApp

    initializer "shopify_app.assets.precompile" do |app|
      app.config.assets.precompile += %w( shopify_app/redirect.js )
    end
  end
end
