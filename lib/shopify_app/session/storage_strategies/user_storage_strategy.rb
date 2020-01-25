module ShopifyApp
  module SessionStorage
    module UserStorageStrategy
      def store(auth_session, user)
        user = find_or_initialize_by(shopify_user_id: user[:id])
        user.shopify_token = auth_session.token
        user.shopify_domain = auth_session.domain
        user.save!
        user.id
      end

      def retrieve(id)
        return unless id
        if user = self.find_by(shopify_user_id: id)
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
