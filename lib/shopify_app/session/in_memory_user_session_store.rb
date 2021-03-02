# frozen_string_literal: true
module ShopifyApp
  class InMemoryUserSessionStore < InMemorySessionStore
    class << self
      def store(session, user)
        id = super
        repo[user.shopify_user_id] = session
        id
      end

      def retrieve_by_shopify_user_id(user_id)
        repo[user_id]
      end
    end
  end
end
