module ShopifyApp
  class AuthenticatedController < ActionController::Base
    include ShopifyApp::AuthenticatedByShopify

    def self.inherited(child_class)
      msg = <<~EOM
        Inheriting from ShopifyApp::AuthenticatedController is deprecated,
        as it prevents you from inheriting from your own application's
        ApplicationController.

        Rather than inheriting in #{child_class}, just include
        ShopifyApp::AuthenticatedByShopify directly.
      EOM

      ActiveSupport::Deprecation.warn msg.gsub(/\n+/, ' ')
    end

  end
end
