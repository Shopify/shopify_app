ShopifyApp.configure do |config|
  config.application_name = 'Example App'
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY']
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET']
  config.scope = 'read_customers, read_orders, write_products'
  config.embedded_app = true
  config.session_repository = Shop
end
