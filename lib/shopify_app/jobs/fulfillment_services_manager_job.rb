module ShopifyApp
  class FulfillmentServicesManagerJob < ActiveJob::Base

    queue_as do
      ShopifyApp.configuration.fulfillment_services_manager_queue_name
    end

    def perform(shop_domain:, shop_token:)
      ShopifyAPI::Session.temp(shop_domain, shop_token) do
        manager = FulfillmentServicesManager.new
        manager.create_fulfillment_services
      end
    end
  end
end
