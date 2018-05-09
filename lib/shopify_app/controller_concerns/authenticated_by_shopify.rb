module ShopifyApp
  module AuthenticatedByShopify
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::Localization
      include ShopifyApp::LoginProtection
      include ShopifyApp::EmbeddedApp

      protect_from_forgery with: :exception
      before_action :login_again_if_different_shop
      around_action :shopify_session
    end

  end
end
