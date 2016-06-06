require 'active_support/concern'
module ShopifyApp
  module WebhookTopicValidator
    class CreationFailed < StandardError; end
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
      topic = options
      unless VALID_WEBHOOK_TOPICS.any? { |valid| valid == topic }
        Rails.logger.warn "A valid topic wasn't entered. Valid topics include: #{VALID_WEBHOOK_TOPICS}"
        raise CreationFailed
      end
    end
  end
end
