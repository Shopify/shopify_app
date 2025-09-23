# frozen_string_literal: true

module ShopifyApp
  module FrameAncestors
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        policy.frame_ancestors(-> do
          domain_host = current_shopify_domain || "*.#{::ShopifyApp.configuration.myshopify_domain}"
          [
            "#{ShopifyAPI::Context.host_scheme}://#{domain_host}",
            "https://admin.#{::ShopifyApp.configuration.unified_admin_domain}",
          ]
        end)
        # Allow app-bridge.js from Shopify CDN for embedded apps
        # This ensures apps work correctly when developers enable strict CSP
        current_script_src = policy.script_src || [:self]
        policy.script_src(*current_script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js")
      end
    end
  end
end
