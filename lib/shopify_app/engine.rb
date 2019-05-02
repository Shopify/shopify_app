module ShopifyApp
  class Engine < Rails::Engine
    engine_name 'shopify_app'
    isolate_namespace ShopifyApp

    initializer "shopify_app.assets.precompile" do |app|
      app.config.assets.precompile += %w[
        shopify_app/redirect.js
        shopify_app/top_level.js
        shopify_app/enable_cookies.js
        shopify_app/request_storage_access.js
        storage_access.svg
      ]
    end
  end
end
