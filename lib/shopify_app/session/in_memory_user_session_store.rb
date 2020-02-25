module ShopifyApp
  class InMemoryUserSessionStore < InMemorySessionStore
    def self.retrieve_by_jwt(payload)
      repo[payload['sub']]
    end
  end
end
