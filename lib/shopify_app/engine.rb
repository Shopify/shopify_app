module ShopifyApp
  class Engine < Rails::Engine
    engine_name 'shopify_app'
    isolate_namespace ShopifyApp

    initializer "shopify_app.assets.precompile" do |app|
      app.config.assets.precompile += %w[
        shopify_app/redirect.js
        shopify_app/itp_polyfill.js
        shopify_app/partition_cookies.js
        shopify_app/storage_access.js
        shopify_app/storage_access_redirect.js
        shopify_app/top_level_interaction.js
        storage_access.svg
      ]
    end
  end
end
