module ShopifyApp
  class WebhooksManager
    class CreationFailed < StandardError; end

    def self.queue(shop_name, token)
      ShopifyApp::WebhooksManagerJob.perform_later(shop_name: shop_name, token: token)
    end

    def initialize(shop_name, token)
      @shop_name, @token = shop_name, token
    end

    def recreate_webhooks!
      destroy_webhooks
      create_webhooks
    end

    def create_webhooks
      return unless required_webhooks.present?

      required_webhooks.each do |webhook|
        create_webhook(webhook)
      end
    end

    def create_webhook(attributes)
      with_shopify_session do
        return webhook_for(attributes[:topic]) if webhook_exists?(attributes[:topic])
        attributes.reverse_merge!(format: 'json')
        webhook = ShopifyAPI::Webhook.create(attributes)
        raise CreationFailed unless webhook.persisted?
        webhook
      end
    end

    def destroy_webhooks
      with_shopify_session do
        ShopifyAPI::Webhook.all.each do |webhook|
          ShopifyAPI::Webhook.delete(webhook.id) if is_required_webhook?(webhook)
        end
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

    def with_shopify_session
      ShopifyAPI::Session.temp(@shop_name, @token) do
        yield
      end
    end

    def webhook_exists?(topic)
      webhook_for(topic).present?
    end

    def webhook_for(topic)
      current_webhooks[topic]
    end

    def current_webhooks
      @current_webhooks ||= ShopifyAPI::Webhook.all.index_by(&:topic)
    end
  end
end
