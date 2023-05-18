# frozen_string_literal: true

ShopifyApp.configure do |config|
  config.application_name = "name"
  config.api_key = ENV["SHOPIFY_APP_API_KEY"] || ENV["SHOPIFY_API_KEY"]
  config.secret = ENV["SHOPIFY_APP_API_SECRET"] || ENV["SHOPIFY_API_SECRET"]
  config.scope = "read_orders read_products"
  config.embedded_app = true
  config.shop_session_repository = "ShopifyApp::InMemoryShopSessionStore"
  config.user_session_repository = "ShopifyApp::InMemoryUserSessionStore"
end
