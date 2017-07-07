module Shopify
  class AfterInstallJob < ActiveJob::Base
    def perform(shop_domain:)
      shop = Shop.find_by(shopify_domain: shop_domain)

      shop.with_shopify_session do
      end
    end
  end
end
