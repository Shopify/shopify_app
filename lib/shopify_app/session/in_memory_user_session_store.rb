# frozen_string_literal: true
module ShopifyApp
  class InMemoryUserSessionStore < InMemorySessionStore
    class << self
      def store(session, user)
        id = super
        repo[user.shopify_user_id] = session
        id
      end

      def retrieve_access_scopes(id)
        repo[id].extra[:scopes]
      end

      def retrieve_access_scopes_by_shopify_user_id(shopify_user_id)
        repo[shopify_user_id].extra[:scopes]
      end

      def retrieve_by_shopify_user_id(user_id)
        repo[user_id]
      end
    end
  end
end
