# frozen_string_literal: true

module ShopifyApp
  module ShopSessionStorageWithScopes
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      ShopifyApp::Logger.deprecated(
        "ShopSessionStorageWithScopes is deprecated and will be removed in v24.0.0. " \
          "Use ShopSessionStorage instead, which now handles access_scopes, expires_at, " \
          "refresh_token, and refresh_token_expires_at automatically.",
        "24.0.0",
      )
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
    end

    class_methods do
      def store(auth_session, *_args)
        shop = find_or_initialize_by(shopify_domain: auth_session.shop)
        shop.shopify_token = auth_session.access_token
        shop.access_scopes = auth_session.scope.to_s

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

      def destroy_by_shopify_domain(domain)
        destroy_by(shopify_domain: domain)
      end

      private

      def construct_session(shop)
        return unless shop

        ShopifyAPI::Auth::Session.new(
          shop: shop.shopify_domain,
          access_token: shop.shopify_token,
          scope: shop.access_scopes,
        )
      end
    end

    def access_scopes=(scopes)
      super(scopes)
    rescue NotImplementedError, NoMethodError
      raise NotImplementedError, "#access_scopes= must be defined to handle storing access scopes: #{scopes}"
    end

    def access_scopes
      super
    rescue NotImplementedError, NoMethodError
      raise NotImplementedError, "#access_scopes= must be defined to hook into stored access scopes"
    end
  end
end
