# frozen_string_literal: true
module ShopifyApp
  class InMemoryShopSessionStore < InMemorySessionStore
    class << self
      def store(session, *args)
        id = super
        repo[session.domain] = session
        id
      end

      def retrieve_scopes_by_shopify_domain(domain)
        repo[domain].extra[:scopes]
      end

      def retrieve_by_shopify_domain(shopify_domain)
        repo[shopify_domain]
      end
    end
  end
end
