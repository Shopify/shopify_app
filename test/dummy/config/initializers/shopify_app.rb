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
      config.api_version = ShopifyAPI::SUPPORTED_ADMIN_VERSIONS[2]
      config.billing = nil
      config.script_tags = nil
      config.embedded_redirect_url = nil

      config.shop_session_repository = ShopifyApp::InMemorySessionStore
      config.user_session_repository = nil
      config.after_authenticate_job = false
      config.reauth_on_access_scope_changes = true
      config.root_url = "/"
      config.new_embedded_auth_strategy = false
      config.check_session_expiry_date = false
      config.custom_post_authenticate_tasks = nil
      config.webhook_jobs_namespace = nil
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
      log_level: :off,
    )
  end
end
