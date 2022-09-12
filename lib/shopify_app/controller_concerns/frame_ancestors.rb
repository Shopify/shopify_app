# frozen_string_literal: true

module ShopifyApp
  module FrameAncestors
    extend ActiveSupport::Concern

    included do
      content_security_policy do |policy|
        policy.frame_ancestors(-> do
          hosts = []
          hosts << "https://#{current_shopify_domain || "*.myshopify.com"}"
          hosts << ENV["HOST"] if ENV["HOST"]
          hosts << "https://admin.shopify.com"

          hosts.join(" ")
        end)
      end
    end
  end
end
