module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    class_methods do
      def store(session)
        shop = self.find_or_initialize_by(shopify_domain: session.url, associated_user_id: session.extra[:associated_user] && session.extra[:associated_user][:id])
        shop.shopify_token = session.token
        shop.extra_json = JSON.generate(session.extra)
        shop.save!
        shop.id
      end

      def retrieve(id)
        return unless id

        if shop = self.find_by(id: id)
          ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token, shop.extra)
        end
      end
    end

  end
end
