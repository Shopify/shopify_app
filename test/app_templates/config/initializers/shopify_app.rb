ShopifyApp.configure do |config|
  config.application_name = "name"
  config.api_key = ENV['SHOPIFY_API_KEY']
  config.secret = ENV['SHOPIFY_API_SECRET']
  config.scope = 'read_orders, read_products'
  config.embedded_app = true
  config.session_repository = 'ShopifyApp::InMemorySessionStore'
end
