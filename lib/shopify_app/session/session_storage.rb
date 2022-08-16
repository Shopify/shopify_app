# frozen_string_literal: true

module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
      validates :shopify_token, presence: true
      validates :api_version, presence: true
    end

    def with_shopify_session(&block)
      ShopifyAPI::Auth::Session.temp(shop: shopify_domain, access_token: shopify_token) do |session|
        block.call session
      end
    end
  end
end
