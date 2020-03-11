module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    def self.retrieve_by_shopify_domain(shopify_domain)
      repo[shopify_domain]
    end
  end
end
