module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    def self.retrieve_by_jwt(payload)
      repo[payload['dest']]
    end
  end
end
