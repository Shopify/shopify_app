module ShopifyApp
  class AuthenticatedController < ApplicationController
    include ShopifyApp::LoginProtection
    before_action :login_again_if_different_shop
    around_action :shopify_session
    layout ShopifyApp.configuration.embedded_app? ? 'embedded_app' : 'application'
  end
end
