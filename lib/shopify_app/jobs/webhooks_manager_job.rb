# frozen_string_literal: true
require 'active_job'

module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
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
