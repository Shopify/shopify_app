# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::Localization
      include ShopifyApp::LoginProtection
      include ShopifyApp::EmbeddedApp
      before_action :login_again_if_different_user_or_shop
      around_action :shopify_session
    end
  end
end
