module ShopifyApp
  class InMemoryUserSessionStore < InMemorySessionStore
    def self.retrieve_by_shopify_user_id(user_id)
      repo[user_id]
    end
  end
end
