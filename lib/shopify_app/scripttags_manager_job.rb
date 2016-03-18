module ShopifyApp
  class ScripttagsManagerJob < ActiveJob::Base
    def perform(params = {})
      shop_name = params.fetch(:shop_name)
      token = params.fetch(:token)

      manager = ScripttagsManager.new(shop_name, token)
      manager.create_scripttags
    end
  end
end
