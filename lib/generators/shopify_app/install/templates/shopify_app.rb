ShopifyApp.configure do |config|
  config.api_key = "<%= opts[:api_key] %>"
  config.secret = "<%= opts[:secret] %>"
  config.scope = "<%= opts[:scope] %>"
  config.embedded_app = <%= embedded_app? %>
end
