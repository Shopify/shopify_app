# frozen_string_literal: true
module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    def self.store(session, scopes, *args)
      id = super
      shopify_api_session = session

      if ShopifyApp.configuration.scopes_exist_on_shop
        shopify_api_session.extra = { scopes: scopes }
      end

      repo[shopify_api_session.domain] = shopify_api_session
      id
    end

    def self.retrieve_by_shopify_domain(shopify_domain)
      repo[shopify_domain]
    end
  end
end
