# frozen_string_literal: true
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
        user.access_scopes = auth_session.extra[:scopes]
        user.save!
        user.id
      end

      def retrieve(id)
        user = find_by(id: id)
        construct_session(user)
      end

      def retrieve_by_shopify_user_id(user_id)
        user = find_by(shopify_user_id: user_id)
        construct_session(user)
      end

      def retrieve_access_scopes_by_shopify_user_id(user_id)
        user = find_by(shopify_user_id: user_id)
        user.access_scopes
      end

      private

      def construct_session(user)
        return unless user
        begin
          scopes = user.access_scopes
        rescue NotImplementedError
          scopes = nil
        end

        ShopifyAPI::Session.new(
          domain: user.shopify_domain,
          token: user.shopify_token,
          api_version: user.api_version,
          extra: { scopes: scopes }
        )
      end
    end
  end
end
