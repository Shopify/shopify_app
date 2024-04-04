# frozen_string_literal: true

module ShopifyApp
  module EnsureHasSession
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::Localization

      if ShopifyApp.configuration.use_new_embedded_auth_strategy?
        include ShopifyApp::TokenExchange
        around_action :activate_shopify_session
      else
        include ShopifyApp::LoginProtection
        before_action :login_again_if_different_user_or_shop
        around_action :activate_shopify_session
        after_action :add_top_level_redirection_headers
      end

      include ShopifyApp::CsrfProtection
      include ShopifyApp::EmbeddedApp
      include ShopifyApp::EnsureBilling
    end
  end
end
