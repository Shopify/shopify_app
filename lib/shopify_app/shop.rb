module ShopifyApp
  module Shop
    extend ActiveSupport::Concern

    included do
      validates :shopify_domain, presence: true, uniqueness: true
      validates :shopify_token, presence: true
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(shopify_domain, shopify_token, &block)
    end

    def connect
      ShopifyAPI::Base.activate_session(
        ShopifyAPI::Session.new(
          ShopifyApp::Utils.sanitize_shop_domain(shopify_domain),
          shopify_token
        )
      )
      nil
    end

  end
end
