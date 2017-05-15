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
      session = ShopifyAPI::Session.new(shopify_domain, shopify_token)
      ShopifyAPI::Base.activate_session(session)
    end

  end
end
