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

        if shop.has_attribute?(:access_scopes)
          shop.access_scopes = auth_session.scope.to_s
        end

        if shop.has_attribute?(:expires_at)
          shop.expires_at = auth_session.expires
        end

        if shop.has_attribute?(:refresh_token)
          shop.refresh_token = auth_session.refresh_token
        end

        if shop.has_attribute?(:refresh_token_expires_at)
          shop.refresh_token_expires_at = auth_session.refresh_token_expires
        end

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

        session_attrs = {
          shop: shop.shopify_domain,
          access_token: shop.shopify_token,
        }

        if shop.has_attribute?(:access_scopes)
          session_attrs[:scope] = shop.access_scopes
        end

        if shop.has_attribute?(:expires_at)
          session_attrs[:expires] = shop.expires_at
        end

        if shop.has_attribute?(:refresh_token)
          session_attrs[:refresh_token] = shop.refresh_token
        end

        if shop.has_attribute?(:refresh_token_expires_at)
          session_attrs[:refresh_token_expires] = shop.refresh_token_expires_at
        end

        ShopifyAPI::Auth::Session.new(**session_attrs)
      end
    end
  end
end
