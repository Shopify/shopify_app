# frozen_string_literal: true

class ShopifyAppConfigurer
  def self.call
    ShopifyApp.configure do |config|
      config.api_key = "key"
      config.old_secret = nil
      config.secret = "secret"
      config.scope = "read_orders, read_products"
      config.shop_access_scopes = nil
      config.user_access_scopes = nil
      config.embedded_app = true
      config.myshopify_domain = "myshopify.com"
      config.api_version = :unstable
      config.billing = nil

      config.shop_session_repository = ShopifyApp::InMemorySessionStore
      config.after_authenticate_job = false
      config.reauth_on_access_scope_changes = true
    end
  end
end

ShopifyAppConfigurer.call
