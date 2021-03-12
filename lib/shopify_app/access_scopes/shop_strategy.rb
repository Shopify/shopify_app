# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class ShopStrategy
      class << self
        def update_access_scopes?(shop_domain)
          shop_access_scopes = shop_access_scopes(shop_domain)
          configuration_access_scopes != shop_access_scopes
        end

        private

        def shop_access_scopes(shop_domain)
          ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(shop_domain)&.access_scopes
        end

        def configuration_access_scopes
          ShopifyAPI::ApiAccess.new(ShopifyApp.configuration.shop_access_scopes)
        end
      end
    end
  end
end
