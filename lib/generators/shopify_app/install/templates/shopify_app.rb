ShopifyApp.configure do |config|
  config.api_key = "<%= @api_key %>"
  config.secret = "<%= @secret %>"
  config.scope = "<%= @scope %>"
  config.embedded_app = <%= embedded_app? %>
end
