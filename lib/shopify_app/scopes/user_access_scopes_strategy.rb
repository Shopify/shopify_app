# frozen_string_literal: true

module ShopifyApp
  class UserAccessScopesStrategy
    class << self
      def scopes_mismatch_by_user_id?(user_id)
        user_scopes = ShopifyApp::SessionRepository.retrieve_user_access_scopes(user_id)
        ShopifyApp::ScopeUtilities.access_scopes_mismatch?(user_scopes, ShopifyApp.configuration.user_access_scopes)
      end

      def scopes_mismatch_by_shopify_user_id?(shopify_user_id)
        user_scopes = ShopifyApp::SessionRepository.retrieve_user_access_scopes_by_shopify_user_id(shopify_user_id)
        ShopifyApp::ScopeUtilities.access_scopes_mismatch?(user_scopes, ShopifyApp.configuration.user_access_scopes)
      end
    end
  end
end
