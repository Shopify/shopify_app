# frozen_string_literal: true

module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    queue_as { ShopifyApp.configuration.webhooks_manager_queue_name }

    def perform(shop_domain:, shop_token:, webhooks:)
      ShopifyApp::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do |session|
        ShopifyApp::WebhooksManager.new(webhooks: webhooks, session: session).recreate_webhooks!
      end
    end
  end
end
