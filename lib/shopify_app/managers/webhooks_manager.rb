module ShopifyApp
  class WebhooksManager
    class CreationFailed < StandardError; end

    def self.queue(shop_domain, shop_token, webhooks)
      ShopifyApp::WebhooksManagerJob.perform_later(
        shop_domain: shop_domain,
        shop_token: shop_token,
        webhooks: webhooks
      )
    end

    attr_reader :required_webhooks

    def initialize(webhooks)
      @required_webhooks = webhooks
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
      ShopifyAPI::Webhook.all.to_a.each do |webhook|
        ShopifyAPI::Webhook.delete(webhook.id) if is_required_webhook?(webhook)
      end

      @current_webhooks = nil
    end

    private

    def is_required_webhook?(webhook)
      required_webhooks.map{ |w| w[:address] }.include? webhook.address
    end

    def create_webhook(attributes)
      attributes.reverse_merge!(format: 'json')
      webhook = ShopifyAPI::Webhook.create(attributes)
      raise CreationFailed, webhook.errors.full_messages.to_sentence unless webhook.persisted?
      webhook
    end

    def webhook_exists?(topic)
      current_webhooks[topic]
    end

    def current_webhooks
      @current_webhooks ||= ShopifyAPI::Webhook.all.to_a.index_by(&:topic)
    end
  end
end
