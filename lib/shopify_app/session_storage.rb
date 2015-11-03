module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    class_methods do
      def store(session)
        shop = self.find_or_initialize_by(shopify_domain: session.url)
        shop.shopify_token = session.token
        shop.save!
        shop.id
      end

      def retrieve(id)
        return unless id

        if shop = self.find_by(id: id)
          ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
        end
      end
    end

  end
end
