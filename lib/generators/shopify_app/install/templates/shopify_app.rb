ShopifyApp.configure do |config|
<% if @application_name.present? %>
  config.application_name = "<%= @application_name %>"
<% end %>
  config.api_key = "<%= @api_key %>"
  config.secret = "<%= @secret %>"
  config.scope = "<%= @scope %>"
  config.embedded_app = <%= embedded_app? %>
end
