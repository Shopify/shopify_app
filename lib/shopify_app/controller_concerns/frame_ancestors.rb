# frozen_string_literal: true

module ShopifyApp
  module FrameAncestors
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        policy.frame_ancestors(-> do
          domain_host = current_shopify_domain || "*.myshopify.com"
          "https://#{domain_host} https://admin.shopify.com"
        end)
      end
    end
  end
end
