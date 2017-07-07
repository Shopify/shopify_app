ShopifyApp.configure do |config|
  config.application_name = "<%= @application_name %>"
  config.api_key = "<%= @api_key %>"
  config.secret = "<%= @secret %>"
  config.scope = "<%= @scope %>"
  config.embedded_app = <%= embedded_app? %>
  config.enable_after_install_actions = false
  config.enable_after_authenticate_actions = false
end
