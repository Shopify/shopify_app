module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    def perform(shop_domain:, shop_token:, webhooks:)
      ShopifyAPI::Session.temp(shop_domain, shop_token) do
        manager = WebhooksManager.new(webhooks)
        manager.create_webhooks
      end
    end
  end
end
