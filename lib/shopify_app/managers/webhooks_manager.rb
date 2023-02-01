# frozen_string_literal: true

require "uri"

module ShopifyApp
  class WebhooksManager
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
        destroy_webhooks
        return unless ShopifyApp.configuration.has_webhooks?

        add_registrations
        ShopifyAPI::Webhooks::Registry.register_all(session: session)
      end

      def destroy_webhooks
        return unless ShopifyApp.configuration.has_webhooks?

        ShopifyApp.configuration.webhooks.each do |attributes|
          ShopifyAPI::Webhooks::Registry.unregister(topic: attributes[:topic])
        end
      end

      def add_registrations
        return unless ShopifyApp.configuration.has_webhooks?

        ShopifyApp.configuration.webhooks.each do |attributes|
          webhook_path = path(attributes)

          ShopifyAPI::Webhooks::Registry.add_registration(
            topic: attributes[:topic],
            delivery_method: attributes[:delivery_method] || :http,
            path: webhook_path,
            handler: webhook_job_klass(webhook_path),
            fields: attributes[:fields]
          )
        end
      end

      private

      def path(webhook_attributes)
        path = webhook_attributes[:path]
        address = webhook_attributes[:address]
        uri = URI(address) if address

        if path.present?
          path
        elsif uri&.path&.present?
          uri.path
        else
          raise ::ShopifyApp::MissingWebhookJobError,
            "The :path attribute is required for webhook registration."
        end
      end

      def webhook_job_klass(path)
        webhook_job_klass_name(path).safe_constantize || raise(::ShopifyApp::MissingWebhookJobError)
      end

      def webhook_job_klass_name(path)
        job_file_name = Pathname(path.to_s).basename

        [ShopifyApp.configuration.webhook_jobs_namespace,
         "#{job_file_name}_job",].compact.join("/").classify
      end
    end
  end
end
