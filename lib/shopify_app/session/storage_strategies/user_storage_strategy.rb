module ShopifyApp
  module SessionStorage
    class UserStorageStrategy
      def initialize(storage_class)
        @storage_class = storage_class
      end

      def store(auth_session, user)
        user = @storage_class.find_or_initialize_by(shopify_user_id: user[:id])
        user.shopify_token = auth_session.token
        user.shopify_domain = auth_session.domain
        user.save!
        user.id
      end

      def retrieve(id)
        return unless id
        if user = @storage_class.find_by(shopify_user_id: id)
          ShopifyAPI::Session.new(
            domain: user.shopify_domain,
            token: user.shopify_token,
            api_version: user.api_version
          )
        end
      end
    end
  end
end
