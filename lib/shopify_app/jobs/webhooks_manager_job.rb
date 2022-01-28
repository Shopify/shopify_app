# frozen_string_literal: true
module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    queue_as do
      ShopifyApp.configuration.webhooks_manager_queue_name
    end

    def perform(shop_domain:, shop_token:, webhooks:)
      ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do
        manager = WebhooksManager.new(webhooks)
        manager.create_webhooks
      end
    end
  end
end
