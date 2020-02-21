module ShopifyApp
  module SessionStorage
    class UserStorageStrategy
      def initialize(storage_class)
        @storage_class = storage_class
      end

      def store(auth_session, user:)
        user_session = @storage_class.find_or_initialize_by(shopify_user_id: user[:id])
        user_session.shopify_token = auth_session.token
        user_session.shopify_domain = auth_session.domain
        user_session.save!
        user_session.id
      end

      def retrieve(id)
        return unless id
        if user_session = @storage_class.find_by(shopify_user_id: id)
          ShopifyAPI::Session.new(
            domain: user_session.shopify_domain,
            token: user_session.shopify_token,
            api_version: user_session.api_version
          )
        end
      end
    end
  end
end
