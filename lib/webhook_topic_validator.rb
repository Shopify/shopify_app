require 'active_support/concern'
module ShopifyApp
  module WebhookTopicValidator
    class CreationFailed < StandardError; end
    class InvalidTopic < StandardError; end
    extend ActiveSupport::Concern

    VALID_WEBHOOK_TOPICS = ['app/uninstalled',
                            'carts/create',
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
    def is_valid_topic?(options = {})
      @topic = options
      unless VALID_WEBHOOK_TOPICS.any? { |valid| valid == @topic }
        raise InvalidTopic
      end
    end

    def invalid_topic_shell_message
      shell.say "#{@topic} is an invalid webhook topic. "\
      "Valid topics include: #{VALID_WEBHOOK_TOPICS}"
    end

    def invalid_topic_logger_message
      Rails.logger.warn "#{@topic} is an invalid webhook topic. "\
      "Valid topics include: #{VALID_WEBHOOK_TOPICS}"
    end
  end
end
