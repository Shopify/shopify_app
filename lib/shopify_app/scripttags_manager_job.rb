module ShopifyApp
  class ScripttagsManagerJob < ActiveJob::Base
    def perform(shop_domain:, shop_token:, scripttags:)
      ShopifyAPI::Session.temp(shop_domain, shop_token) do
        manager = ScripttagsManager.new(scripttags)
        manager.create_scripttags
      end
    end
  end
end
