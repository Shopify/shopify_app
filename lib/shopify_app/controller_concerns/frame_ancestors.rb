# frozen_string_literal: true

module ShopifyApp
  module FrameAncestors
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        policy.frame_ancestors(-> do
          shop_domain = ShopifyApp::Utils.sanitize_shop_domain(params[:shop]) if params[:shop].present?
          domain_host = shop_domain || "*.#{::ShopifyApp.configuration.myshopify_domain}"
          "#{ShopifyAPI::Context.host_scheme}://#{domain_host} https://admin.shopify.com"
        end)
      end
    end
  end
end
