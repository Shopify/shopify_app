# frozen_string_literal: true

module ShopifyApp
  module EnsureHasSession
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::Localization
      include ShopifyApp::LoginProtection
      include ShopifyApp::CsrfProtection
      include ShopifyApp::EmbeddedApp
      include ShopifyApp::EnsureBilling

      before_action :login_again_if_different_user_or_shop
      around_action :activate_shopify_session
      after_action :add_top_level_redirection_headers
    end
  end
end
