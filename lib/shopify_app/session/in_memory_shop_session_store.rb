# frozen_string_literal: true

module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    class << self
      def store(session, *args)
        id = super
        repo[session.shop] = session
        id
      end

      def retrieve_by_shopify_domain(shopify_domain)
        repo[shopify_domain]
      end
    end
  end
end
