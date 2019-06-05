module ShopifyApp
  module SessionStorage
    class UserStorageStrategy

      def self.store(session, user)
        user = User.find_or_initialize_by(shopify_user_id: user[:id])
        user.shopify_token = session.token
        user.shopify_domain = session.domain
        user.save!
        user.id
      end

      def self.retrieve(id)
        return unless id
        if user = User.find_by(shopify_user_id: id)
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
