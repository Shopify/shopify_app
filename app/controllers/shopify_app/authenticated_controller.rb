module ShopifyApp
  class AuthenticatedController < ActionController::Base
    include ShopifyApp::AuthenticatedByShopify
  end
end
