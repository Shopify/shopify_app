# frozen_string_literal: true
class ShopifyAppConfigurer
  def self.call
    ShopifyApp.configure do |config|
      config.api_key = "key"
      config.secret = "secret"
      config.scope = 'read_orders, read_products'
      config.embedded_app = true
      config.myshopify_domain = 'myshopify.com'
      config.api_version = :unstable
      config.allow_jwt_authentication = true
    end
  end
end

ShopifyAppConfigurer.call
