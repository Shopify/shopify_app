module ShopifyApp
  class AuthenticatedController < ActionController::Base
    include ShopifyApp::Localization
    include ShopifyApp::LoginProtection

    before_action :set_locale
    before_action :login_again_if_different_shop
    around_action :shopify_session

    layout ShopifyApp.configuration.embedded_app? ? 'embedded_app' : 'application'
  end
end
