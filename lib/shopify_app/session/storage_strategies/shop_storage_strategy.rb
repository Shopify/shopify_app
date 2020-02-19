module ShopifyApp
  module SessionStorage
    class ShopStorageStrategy
      def initialize(storage_class)
        @storage_class = storage_class
      end

      def store(auth_session, *args)
        shop = @storage_class.find_or_initialize_by(shopify_domain: auth_session.domain)
        shop.shopify_token = auth_session.token
        shop.save!
        shop.id
      end

      def retrieve(id)
        return unless id
        if shop = @storage_class.find_by(id: id)
          ShopifyAPI::Session.new(
            domain: shop.shopify_domain,
            token: shop.shopify_token,
            api_version: shop.api_version
          )
        end
      end
    end
  end
end
