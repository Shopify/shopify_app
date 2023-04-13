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
      config.api_version = ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION
      config.billing = nil
      config.scripttags = nil
      config.embedded_redirect_url = nil

      config.shop_session_repository = ShopifyApp::InMemorySessionStore
      config.after_authenticate_job = false
      config.reauth_on_access_scope_changes = true
    end

    setup_context
  end

  def self.setup_context
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      api_version: ShopifyApp.configuration.api_version,
      host_name: "test.host",
      scope: ShopifyApp.configuration.scope,
      is_private: false,
      is_embedded: ShopifyApp.configuration.embedded_app,
      session_storage: ShopifyApp::SessionRepository,
      log_level: :off,
    )
  end
end
