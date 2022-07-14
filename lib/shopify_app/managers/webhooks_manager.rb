# frozen_string_literal: true

module ShopifyApp
  class WebhooksManager
    class CreationFailed < StandardError; end

    class << self
      def queue(shop_domain, shop_token)
        ShopifyApp::WebhooksManagerJob.perform_later(
          shop_domain: shop_domain,
          shop_token: shop_token
        )
      end

      def create_webhooks(session:)
        return unless ShopifyApp.configuration.has_webhooks?
        ShopifyAPI::Webhooks::Registry.register_all(session: session)
      end

      def recreate_webhooks!(session:)
        destroy_webhooks(session: session)
        return unless ShopifyApp.configuration.has_webhooks?
        add_registrations
        ShopifyAPI::Webhooks::Registry.register_all(session: session)
      end

      def destroy_webhooks(session:)
        return unless ShopifyApp.configuration.has_webhooks?

        ShopifyApp.configuration.webhooks.each do |attributes|
          ShopifyAPI::Webhooks::Registry.unregister(topic: attributes[:topic], session: session)
        end
      end

      def add_registrations
        return unless ShopifyApp.configuration.has_webhooks?

        ShopifyApp.configuration.webhooks.each do |attributes|
          ShopifyAPI::Webhooks::Registry.add_registration(
            topic: attributes[:topic],
            delivery_method: attributes[:delivery_method] || :http,
            path: attributes[:address],
            handler: webhook_job_klass(attributes[:topic]),
            fields: attributes[:fields]
          )
        end
      end

      private

      def webhook_job_klass(topic)
        webhook_job_klass_name(topic).safe_constantize || raise(ShopifyApp::MissingWebhookJobError)
      end

      def webhook_job_klass_name(topic)
        [ShopifyApp.configuration.webhook_jobs_namespace, "#{topic.gsub("/", "_")}_job"].compact.join("/").classify
      end
    end
  end
end
