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
    end

    setup_context
  end

  def self.setup_context
    # ShopifyAPI context is now handled by ShopifyApp::SessionContext
    # No need to call ShopifyAPI::Context.setup anymore
  end
end

Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    # ShopifyAPI context is now handled by ShopifyApp::SessionContext
    # No need to call ShopifyAPI::Context.setup anymore

    ShopifyApp::WebhooksManager.add_registrations
  end
end
