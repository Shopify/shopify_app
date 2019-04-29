module ShopifyApp
  class ScripttagsManagerJob < ActiveJob::Base

    queue_as do
      ShopifyApp.configuration.scripttags_manager_queue_name
    end

    def perform(shop_domain:, shop_token:, scripttags:)
      api_version = ShopifyApp.configuration.api_version
      ShopifyAPI::Session.temp(domain: shop_domain, token: shop_token, api_version: api_version) do
        manager = ScripttagsManager.new(scripttags, shop_domain)
        manager.create_scripttags
      end
    end
  end
end
