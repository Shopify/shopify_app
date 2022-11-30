# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class UserStrategy
      class << self
        def update_access_scopes?(user_id: nil, shopify_user_id: nil)
          return update_access_scopes_for_user_id?(user_id) if user_id
          return update_access_scopes_for_shopify_user_id?(shopify_user_id) if shopify_user_id

          raise(::ShopifyApp::InvalidInput,
            "#update_access_scopes? requires user_id or shopify_user_id parameter inputs")
        end

        def covered_scopes?(current_shopify_session)
          # NOTE: this not Ruby's `covers?` method, it is defined in ShopifyAPI::Auth::AuthScopes
          current_shopify_session.scope.to_a.empty? || current_shopify_session.scope.covers?(ShopifyAPI::Context.scope)
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
          ShopifyApp::SessionRepository.retrieve_user_session(user_id)&.scope
        end

        def user_access_scopes_by_shopify_user_id(shopify_user_id)
          ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(shopify_user_id)&.scope
        end

        def configuration_access_scopes
          ShopifyAPI::Auth::AuthScopes.new(ShopifyApp.configuration.user_access_scopes)
        end
      end
    end
  end
end
