# frozen_string_literal: true
module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    def self.store(session, *args)
      id = super
      repo[session.domain] = session
      id
    end

    def self.store_with_scopes(session, scopes)
      id = super.store(session)
      repo[session.domain] = session
      repo[session.domain].extra = { scopes: scopes }
      id
    end

    def self.retrieve_by_shopify_domain(shopify_domain)
      repo[shopify_domain]
    end
  end
end
