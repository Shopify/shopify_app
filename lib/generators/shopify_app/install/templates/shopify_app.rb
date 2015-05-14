ShopifyApp.configure do |config|
  config.api_key = "<%= opts[:api_key] || '<api_key>' %>"
  config.secret = "<%= opts[:secret] || '<secret>' %>"
  config.scope = "<%= opts[:scope] || 'read_orders, read_products' %>"
  config.embedded_app = <%= opts[:embedded_app] || true %>
  config.routes = true
end
