ShopifyApp.configure do |config|
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY']
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET']
  config.redirect_uri = "http://localhost:3000/auth/shopify/callback"
  config.scope = 'read_customers, read_orders, write_products'
  config.embedded_app = true
end
