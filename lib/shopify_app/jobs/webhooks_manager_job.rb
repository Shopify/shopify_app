# frozen_string_literal: true

module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    queue_as do
      ShopifyApp.configuration.webhooks_manager_queue_name
    end

    def perform(shop_domain:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop.shopify_token) do |session|
        WebhooksManager.create_webhooks(session: session)
      end
    end
  end
end
