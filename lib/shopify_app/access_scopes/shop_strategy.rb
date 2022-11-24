# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class ShopStrategy
      class << self
        def update_access_scopes?(shop_domain)
          shop_access_scopes = shop_access_scopes(shop_domain)
          result = configuration_access_scopes != shop_access_scopes
          ShopifyApp::Logger.debug("Checking if should update access scopes, result: #{result}")
          result
        end

        private

        def shop_access_scopes(shop_domain)
          ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(shop_domain)&.scope
        end

        def configuration_access_scopes
          ShopifyAPI::Auth::AuthScopes.new(ShopifyApp.configuration.shop_access_scopes)
        end
      end
    end
  end
end
