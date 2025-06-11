# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class UserStrategy
      class << self
        def update_access_scopes?(user_id: nil, shopify_domain: nil, session: nil)
          return update_access_scopes_for_user_id?(user_id) if user_id
          return update_access_scopes_for_shopify_domain?(shopify_domain) if shopify_domain

          update_access_scopes_for_session?(session) if session
        end

        def covers_scopes?(current_shopify_session)
          return true unless current_shopify_session
          return true if current_shopify_session.scope.nil?

          # NOTE: this not Ruby's `covers?` method, it is defined in ShopifyApp::Auth::AuthScopes
          current_shopify_session.scope.to_a.empty? || current_shopify_session.scope.covers?(configuration_access_scopes)
        end

        private

        def update_access_scopes_for_user_id?(user_id)
          user_access_scopes = user_access_scopes_by_user_id(user_id)
          configuration_access_scopes != user_access_scopes
        end

        def update_access_scopes_for_shopify_domain?(shopify_domain)
          user_access_scopes = user_access_scopes_by_shopify_domain(shopify_domain)
          configuration_access_scopes != user_access_scopes
        end

        def update_access_scopes_for_session?(session)
          user_access_scopes = session&.scope
          configuration_access_scopes != user_access_scopes
        end

        def user_access_scopes_by_user_id(user_id)
          ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(user_id)&.scope
        end

        def user_access_scopes_by_shopify_domain(shopify_domain)
          ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(shopify_domain)&.scope
        end

        def configuration_access_scopes
          ShopifyApp::Auth::AuthScopes.new(ShopifyApp.configuration.user_access_scopes)
        end
      end
    end
  end
end
