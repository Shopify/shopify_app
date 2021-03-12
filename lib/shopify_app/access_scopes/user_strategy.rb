# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class UserStrategy
      class InvalidInput < StandardError; end

      class << self
        def update_access_scopes?(user_id: nil, shopify_user_id: nil)
          return update_access_scopes_for_user_id?(user_id) if user_id
          return update_access_scopes_for_shopify_user_id?(shopify_user_id) if shopify_user_id
          raise(InvalidInput, '#update_access_scopes? requires user_id or shopify_user_id parameter inputs')
        end

        private

        def update_access_scopes_for_user_id?(user_id)
          user_access_scopes = user_access_scopes_by_user_id(user_id)
          configuration_access_scopes != user_access_scopes
        end

        def update_access_scopes_for_shopify_user_id?(shopify_user_id)
          user_access_scopes = user_access_scopes_by_shopify_user_id(shopify_user_id)
          configuration_access_scopes != user_access_scopes
        end

        def user_access_scopes_by_user_id(user_id)
          ShopifyApp::SessionRepository.retrieve_user_session(user_id)&.access_scopes
        end

        def user_access_scopes_by_shopify_user_id(shopify_user_id)
          ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(shopify_user_id)&.access_scopes
        end

        def configuration_access_scopes
          ShopifyAPI::ApiAccess.new(ShopifyApp.configuration.user_access_scopes)
        end
      end
    end
  end
end
