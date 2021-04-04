module ShopifyApp
  module Webhooks
    class GraphqlAdapter < BaseAdapter
      ALL_WEBHOOKS_QUERY = <<-'GRAPHQL'
        query {
          webhookSubscriptions(first: 250) {
            edges {
              node {
                id
                topic
                endpoint {
                  ... on WebhookHttpEndpoint {
                    callbackUrl
                  }
                }
              }
            }
          }
        }
      GRAPHQL
      CREATE_WEBHOOK_MUTATION = <<-'GRAPHQL'
        mutation($topic: WebhookSubscriptionTopic!, $webhookSubscription: WebhookSubscriptionInput!) {
          webhookSubscriptionCreate(topic: $topic, webhookSubscription: $webhookSubscription) {
            webhookSubscription {
              id
              topic
            }
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL
      DELETE_WEBHOOK_MUTATION = <<-'GRAPHQL'
        mutation($id: ID!) {
          webhookSubscriptionDelete(id: $id) {
            deletedWebhookSubscriptionId
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      def create_webhooks
        return unless required_webhooks.present?

        required_webhooks.each do |webhook|
          topic = graphql_topic(webhook[:topic])
          create_webhook(webhook) unless webhook_exists?(topic)
        end
      end

      def destroy_webhooks
        current_webhooks.each do |webhook|
          destroy_webhook(webhook) if required_webhook?(webhook)
        end

        @current_webhooks = nil
      end

      private

      def current_webhooks
        @current_webhooks ||= begin
          client = ShopifyAPI::GraphQL.client
          query = client.parse(ALL_WEBHOOKS_QUERY)
          result = client.query(query)
          if result.errors.any?
            raise ShopifyApp::WebhooksManager::CreationFailed, result.errors.messages.to_json
          end

          result.data.webhook_subscriptions.edges.map do |edge|
            edge.node.to_h
          end
        end
      end

      # tranform topic to GraphQL format (eg APP_SUBSCRIPTIONS_UPDATE)
      def graphql_topic(topic)
        topic.gsub('/', ' ').gsub(' ', '_').upcase
      end

      def webhook_exists?(topic)
        current_webhooks.any? do |webhook|
          webhook["topic"] == topic
        end
      end

      def required_webhook?(webhook)
        webhook_address = webhook.dig("endpoint", "callbackUrl")
        required_webhooks.any? { |w| w[:address] == webhook_address }
      end

      def create_webhook(attributes)
        topic = graphql_topic(attributes[:topic])
        address = attributes[:address]

        client = ShopifyAPI::GraphQL.client
        query = client.parse(CREATE_WEBHOOK_MUTATION)
        webhook = client.query(query,
          variables: {
            topic: topic,
            webhookSubscription: { callbackUrl: address, format: 'JSON' }
          }
        )
        if webhook.errors.any?
          raise ShopifyApp::WebhooksManager::CreationFailed, webhook.errors.messages.to_json
        end
        if webhook.data.webhook_subscription_create.user_errors.any?
          raise ShopifyApp::WebhooksManager::CreationFailed, webhook.data.webhook_subscription_create.user_errors.map(&:message).to_sentence
        end
      end

      def destroy_webhook(webhook)
        client = ShopifyAPI::GraphQL.client
        query = client.parse(DELETE_WEBHOOK_MUTATION)
        webhook = client.query(query, variables: { id: webhook["id"] })
        if webhook.errors.any?
          raise ShopifyApp::WebhooksManager::DeletionFailed, webhook.errors.messages.to_json
        end
        if webhook.data.webhook_subscription_delete.user_errors.any?
          raise ShopifyApp::WebhooksManager::DeletionFailed, webhook.data.webhook_subscription_delete.user_errors.map(&:message).to_sentence
        end
      end
    end
  end
end
