# frozen_string_literal: true
module ShopifyApp
  module ShopSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
    end

    class_methods do
      def store(auth_session, *_args)
        shop = set_required_shopify_session_attributes(auth_session)
        shop.save!
        shop.id
      end

      def store_with_scopes(auth_session, scopes)
        shop = set_required_shopify_session_attributes(auth_session)
        shop.scopes = scopes
        shop.save!
        shop.id
      end

      def retrieve(id)
        shop = find_by(id: id)
        construct_session(shop)
      end

      def retrieve_by_shopify_domain(domain)
        shop = find_by(shopify_domain: domain)
        construct_session(shop)
      end

      private

      def set_required_shopify_session_attributes(auth_session)
        shop = find_or_initialize_by(shopify_domain: auth_session.domain)
        shop.shopify_token = auth_session.token
        shop
      end

      def construct_session(shop)
        return unless shop
        shopify_api_session = ShopifyAPI::Session.new(
          domain: shop.shopify_domain,
          token: shop.shopify_token,
          api_version: shop.api_version,
        )

        if ShopifyApp.configuration.scopes_exist_on_shop
          shopify_api_session.extra = { scopes: shop.scopes }
        end

        shopify_api_session
      end
    end
  end
end
