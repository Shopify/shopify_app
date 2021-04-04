# frozen_string_literal: true
module ShopifyApp
  module Webhooks
    class RestAdapter < BaseAdapter
      def create_webhooks
        return unless required_webhooks.present?

        required_webhooks.each do |webhook|
          create_webhook(webhook) unless webhook_exists?(webhook[:topic])
        end
      end

      def destroy_webhooks
        ShopifyAPI::Webhook.all.to_a.each do |webhook|
          ShopifyAPI::Webhook.delete(webhook.id) if required_webhook?(webhook)
        end

        @current_webhooks = nil
      end

      private

      def required_webhook?(webhook)
        required_webhooks.map { |w| w[:address] }.include?(webhook.address)
      end

      def create_webhook(attributes)
        attributes.reverse_merge!(format: 'json')
        webhook = ShopifyAPI::Webhook.create(attributes)
        unless webhook.persisted?
          raise ShopifyApp::WebhooksManager::CreationFailed, webhook.errors.full_messages.to_sentence
        end
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
end
