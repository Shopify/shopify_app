# frozen_string_literal: true

module ShopifyApp
  class ShopAccessScopesStrategy
    class << self
      def scopes_mismatch?(shop_domain)
        shop_scopes = ShopifyApp::SessionRepository.retrieve_shop_access_scopes(shop_domain)
        ShopifyApp::ScopeUtilities.access_scopes_mismatch?(shop_scopes, ShopifyApp.configuration.shop_access_scopes)
      end
    end
  end
end
