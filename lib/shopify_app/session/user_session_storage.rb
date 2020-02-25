module ShopifyApp
  module UserSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true
    end

    class_methods do
      def store(auth_session, user)
        user = find_or_initialize_by(shopify_user_id: user[:id])
        user.shopify_token = auth_session.token
        user.shopify_domain = auth_session.domain
        user.save!
        user.id
      end

      def retrieve(id)
        user = find_by(id: id)
        construct_session(user)
      end

      def retrieve_by_jwt(payload)
        user = find_by(shopify_user_id: payload['sub'])
        construct_session(user)
      end

      private

      def construct_session(user)
        return unless user
        ShopifyAPI::Session.new(
          domain: user.shopify_domain,
          token: user.shopify_token,
          api_version: user.api_version,
        )
      end
    end
  end
end
