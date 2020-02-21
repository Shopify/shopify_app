module ShopifyApp
  module SessionStorage
    class ShopStorageStrategy
      def initialize(storage_class)
        @storage_class = storage_class
      end

      def store(auth_session, *args)
        shop_session = @storage_class.find_or_initialize_by(shopify_domain: auth_session.domain)
        shop_session.shopify_token = auth_session.token
        shop_session.save!
        shop_session.id
      end

      def retrieve(id)
        return unless id
        if shop_session = @storage_class.find_by(id: id)
          ShopifyAPI::Session.new(
            domain: shop_session.shopify_domain,
            token: shop_session.shopify_token,
            api_version: shop_session.api_version
          )
        end
      end
    end
  end
end
