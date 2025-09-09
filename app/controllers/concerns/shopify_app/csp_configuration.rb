# frozen_string_literal: true

module ShopifyApp
  module CspConfiguration
    extend ActiveSupport::Concern

    included do
      class_exec do
        content_security_policy do |policy|
          policy.script_src(*policy.script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js")
        end
      end
    end
  end
end
