# frozen_string_literal: true

ShopifyApp.configure do |config|
  config.api_key = "key"
  config.secret = "secret"
  config.scope = "read_orders, read_products"
  config.embedded_app = true
  config.webhooks = [
    { topic: "carts/update", path: "webhooks/carts_update" },
  ]
end
