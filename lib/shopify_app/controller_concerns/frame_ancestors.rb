# frozen_string_literal: true

module ShopifyApp
  module FrameAncestors
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        policy.frame_ancestors(-> do
          domain_host = current_shopify_domain || "*.#{::ShopifyApp.configuration.myshopify_domain}"
          [
            "#{ShopifyApp::SessionContext.host_scheme}://#{domain_host}",
            "https://admin.#{::ShopifyApp.configuration.unified_admin_domain}",
          ]
        end)
      end
    end

    def content_security_policy_sources(domain_host:)
      [
        "https://#{domain_host}",
        "#{ShopifyApp::SessionContext.host_scheme}://#{domain_host}",
      ]
    end
  end
end
