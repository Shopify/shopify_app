# frozen_string_literal: true

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform(shop_domain:)
      shop = Shop.find_by(shopify_domain: shop_domain)

      shop.with_shopify_session do |session|
      end
    end
  end
end
