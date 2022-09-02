# frozen_string_literal: true

module ShopifyApp
  module EnsureBilling
    class BillingError < StandardError
      attr_accessor :message
      attr_accessor :errors

      def initialize(message, errors)
        super
        @message = message
        @errors = errors
      end
    end
  end
end
