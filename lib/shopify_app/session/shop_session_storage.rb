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
        shop = find_or_initialize_by(shopify_domain: auth_session.shop)
        shop.shopify_token = auth_session.access_token
        shop.save!
      end

      def retrieve(id)
        shop = find_by(id: id)
        construct_session(shop)
      end

      def retrieve_by_shopify_domain(domain)
        shop = find_by(shopify_domain: domain)
        construct_session(shop)
      end

      def destroy_by_shopify_domain(domain)
        destroy_by(shopify_domain: domain)
      end

      private

      def construct_session(shop)
        return unless shop

        ShopifyApp::Auth::Session.new(
          shop: shop.shopify_domain,
          access_token: shop.shopify_token,
          scope: shop.scope,
        )
      end
    end

    def save_session_to_repository
      if ShopifyApp.configuration.shop_session_repository.blank? || ShopifyApp::SessionRepository.shop_storage.blank?
        return
      end

      ShopifyApp::SessionRepository.store_shop_session(session)
    end
  end
end
