# frozen_string_literal: true

namespace :shopify do
  desc "Rotate shopify tokens for all active shops"
  task :rotate_shopify_tokens, [:refresh_token] => :environment do |_t, args|
    all_active_shops.find_each do |shop|
      Shopify::RotateShopifyTokenJob.perform_later(
        shop_domain: shop.shopify_domain,
        refresh_token: args[:refresh_token]
      )
    end
  end

  # Its implementation will depend on the app configuration. Change accordingly.
  def all_active_shops
    Shop.all
  end
end
