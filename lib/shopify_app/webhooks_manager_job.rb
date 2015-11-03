module ShopifyApp
  class WebhooksManagerJob < ActiveJob::Base
    def perform(params = {})
      shop_name = params.fetch(:shop_name)
      token = params.fetch(:token)

      manager = WebhooksManager.new(shop_name, token)
      manager.create_webhooks
    end
  end
end
