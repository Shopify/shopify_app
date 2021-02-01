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
        shop = find_or_initialize_by(shopify_domain: auth_session.domain)
        shop.shopify_token = auth_session.token
        update_merchant_scopes(shop, auth_session.extra[:scopes])

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

      def retrieve_scopes_by_shopify_domain(domain)
        shop = find_by(shopify_domain: domain)
        merchant_scopes(shop)
      end

      def update_merchant_scopes(shop, scopes)
        Rails.logger.warn("#{shop.class}.update_scopes must be overriden to handle storing scopes: #{scopes}")
      end

      def merchant_scopes(shop)
        raise NotImplementedError, "#{shop.class}.merchant_scopes must be defined to hook into stored scopes"
      end

      private

      def construct_session(shop)
        return unless shop
        begin
          scopes = merchant_scopes(shop)
        rescue NotImplementedError
          scopes = nil
        end

        ShopifyAPI::Session.new(
          domain: shop.shopify_domain,
          token: shop.shopify_token,
          api_version: shop.api_version,
          extra: { scopes: scopes }
        )
      end
    end
  end
end
