# frozen_string_literal: true
module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    self.log_arguments = false

    queue_as do
      ShopifyApp.configuration.webhooks_manager_queue_name
    end

    def perform(shop_domain:, shop_token:, webhooks:)
      api_version = ShopifyApp.configuration.api_version
      ShopifyAPI::Session.temp(domain: shop_domain, token: shop_token, api_version: api_version) do
        manager = WebhooksManager.new(webhooks)
        manager.create_webhooks
      end
    end
  end
end
