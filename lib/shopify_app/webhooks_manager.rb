module ShopifyApp
  class WebhooksManager
    class CreationFailed < StandardError; end
    class InvalidTopic < StandardError; end

    VALID_WEBHOOK_TOPICS = ['carts/create',
                            'carts/update',
                            'checkouts/create',
                            'checkouts/delete',
                            'checkouts/update',
                            'collections/create',
                            'collections/delete',
                            'collections/update',
                            'customer_groups/create',
                            'customer_groups/delete',
                            'customer_groups/update',
                            'customers/create',
                            'customers/delete',
                            'customers/disable',
                            'customers/enable',
                            'customers/update',
                            'disputes/create',
                            'disputes/update',
                            'fulfillment_events/create',
                            'fulfillment_events/delete',
                            'fulfillments/create',
                            'fulfillments/update',
                            'order_transactions/create',
                            'orders/cancelled',
                            'orders/create',
                            'orders/delete',
                            'orders/fulfilled',
                            'orders/paid',
                            'orders/partially_fulfilled',
                            'orders/updated',
                            'products/create',
                            'products/delete',
                            'products/update',
                            'refunds/create',
                            'shop/update',
                            'themes/publish'
                          ]

    def self.queue(shop_domain, shop_token)
      ShopifyApp::WebhooksManagerJob.perform_later(shop_domain: shop_domain, shop_token: shop_token)
    end

    def recreate_webhooks!
      destroy_webhooks
      create_webhooks
    end

    def create_webhooks
      return unless required_webhooks.present?

      required_webhooks.each do |webhook|
        create_webhook(webhook) unless webhook_exists?(webhook[:topic])
      end
    end

    def destroy_webhooks
      ShopifyAPI::Webhook.all.each do |webhook|
        ShopifyAPI::Webhook.delete(webhook.id) if is_required_webhook?(webhook)
      end

      @current_webhooks = nil
    end

    private

    def required_webhooks
      ShopifyApp.configuration.webhooks
    end

    def is_required_webhook?(webhook)
      required_webhooks.map{ |w| w[:address] }.include? webhook.address
    end

    def create_webhook(attributes)
      attributes.reverse_merge!(format: 'json')
      webhook = ShopifyAPI::Webhook.create(attributes)
      raise CreationFailed unless webhook.persisted?
      webhook
    end

    def webhook_exists?(topic)
      current_webhooks[topic]
    end

    def current_webhooks
      @current_webhooks ||= ShopifyAPI::Webhook.all.index_by(&:topic)
    end
  end
end
