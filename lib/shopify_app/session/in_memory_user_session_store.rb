# frozen_string_literal: true
module ShopifyApp
  class InMemoryUserSessionStore < InMemorySessionStore
    def self.store(session, user)
      id = super
      repo[user.shopify_user_id] = session
      id
    end

    def self.retrieve_by_shopify_user_id(user_id)
      repo[user_id]
    end
  end
end
