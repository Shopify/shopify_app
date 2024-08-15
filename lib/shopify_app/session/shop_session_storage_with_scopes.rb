# frozen_string_literal: true

module ShopifyApp
  module ShopSessionStorageWithScopes
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
    end

    class_methods do
      def store(auth_session, *_args)
        shop = find_or_initialize_by(shopify_domain: auth_session.shop)
        shop.shopify_token = auth_session.access_token
        shop.access_scopes = auth_session.scope.to_s
        shop.expires_at = auth_session.expires
        shop.refresh_token = auth_session.refresh_token

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
          expires: shop.expires_at,
          refresh_token: shop.refresh_token,
        )
      end
    end

    def with_shopify_session(&block)
      current_offline_session = ShopifyAPI::Auth::Session.temp(shop: shopify_domain, access_token: shopify_token)
      
      if current_offline_session.almost_expired?
        new_offline_session = ShopifyAPI::Auth::RefreshToken.refresh(shop: shopify_domain, refresh_token: refresh_token)
        self.shopify_token = new_offline_session.access_token
        self.access_scopes = new_offline_session.scope.to_s
        self.expires_at = new_offline_session.expires_at
        self.refresh_token = new_offline_session.refresh_token

        save!
      end
      
      ShopifyAPI::Auth::Session.temp(shop: shopify_domain, access_token: shopify_token) do |session|
        block.call(session)
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

    def expires_at=(expires_at)
      super
    rescue NotImplementedError, NoMethodError
      if ShopifyApp.configuration.handle_offline_token_expiry
        raise NotImplementedError,
          "#expires_at= must be defined to handle offline token expiry"
      end
    end

    def expires_at
      super
    rescue NotImplementedError, NoMethodError
      if ShopifyApp.configuration.handle_offline_token_expiry
        raise NotImplementedError, "#expires_at must be defined to handle offline token expiry"
      end

      nil
    end

    def refresh_token=(refresh_token)
      super
    rescue NotImplementedError, NoMethodError
      if ShopifyApp.configuration.handle_offline_token_expiry
        raise NotImplementedError,
          "#refresh_token= must be defined to handle offline token expiry"
      end
    end

    def refresh_token
      super
    rescue NotImplementedError, NoMethodError
      if ShopifyApp.configuration.handle_offline_token_expiry
        raise NotImplementedError, "#refresh_token must be defined to handle offline token expiry"
      end

      nil
    end
  end
end
