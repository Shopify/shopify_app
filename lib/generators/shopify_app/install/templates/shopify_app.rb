ShopifyApp.configure do |config|
  config.api_key = '<%= options[:api_key] %>'
  config.secret = '<%= options[:secret] %>'
  config.scope = '<%= options[:scope] || "read_orders, read_products" %>'
  config.embedded_app = <%= options[:embedded_app] %>
end
