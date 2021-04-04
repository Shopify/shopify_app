# frozen_string_literal: true
module ShopifyApp
  module Webhooks
    class BaseAdapter
      attr_reader :required_webhooks

      def initialize(webhooks)
        @required_webhooks = webhooks
      end
    end
  end
end
