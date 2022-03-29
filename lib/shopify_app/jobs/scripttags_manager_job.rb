# frozen_string_literal: true

module ShopifyApp
  class ScripttagsManagerJob < ActiveJob::Base
    queue_as do
      ShopifyApp.configuration.scripttags_manager_queue_name
    end

    def perform(shop_domain:, shop_token:, scripttags:)
      ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do
        manager = ScripttagsManager.new(scripttags, shop_domain)
        manager.create_scripttags
      end
    end
  end
end
