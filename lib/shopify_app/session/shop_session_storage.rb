# frozen_string_literal: true

module ShopifyApp
  module ShopSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
    end

    def with_shopify_session(auto_refresh: true, &block)
      refresh_token_if_expired! if auto_refresh
      super(&block)
    end

    def refresh_token_if_expired!
      return unless should_refresh?
      raise RefreshTokenExpiredError if refresh_token_expired?

      # Acquire row lock to prevent concurrent refreshes
      with_lock do
        reload
        # Check again after lock - token might have been refreshed by another process
        return unless should_refresh?

        perform_token_refresh!
      end
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

    def perform_token_refresh!
      new_session = ShopifyAPI::Auth::RefreshToken.refresh_access_token(
        shop: shopify_domain,
        refresh_token: refresh_token,
      )

      update!(
        shopify_token: new_session.access_token,
        expires_at: new_session.expires,
        refresh_token: new_session.refresh_token,
        refresh_token_expires_at: new_session.refresh_token_expires,
      )
    end

    def should_refresh?
      return false unless has_attribute?(:expires_at) && expires_at.present?
      return false unless has_attribute?(:refresh_token) && refresh_token.present?
      return false unless has_attribute?(:refresh_token_expires_at) && refresh_token_expires_at.present?

      expires_at <= Time.now
    end

    def refresh_token_expired?
      return false unless has_attribute?(:refresh_token_expires_at) && refresh_token_expires_at.present?

      refresh_token_expires_at <= Time.now
    end
  end
end
