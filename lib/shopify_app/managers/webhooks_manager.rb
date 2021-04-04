# frozen_string_literal: true
module ShopifyApp
  class WebhooksManager
    class CreationFailed < StandardError; end

    class DeletionFailed < StandardError; end

    def self.queue(shop_domain, shop_token, webhooks)
      ShopifyApp::WebhooksManagerJob.perform_later(
        shop_domain: shop_domain,
        shop_token: shop_token,
        webhooks: webhooks
      )
    end

    def initialize(webhooks, adapter:)
      @adapter = adapter.new(webhooks)
    end

    def recreate_webhooks!
      destroy_webhooks
      create_webhooks
    end

    def create_webhooks
      @adapter.create_webhooks
    end

    def destroy_webhooks
      @adapter.destroy_webhooks
    end
  end
end
