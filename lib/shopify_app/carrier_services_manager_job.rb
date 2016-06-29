module ShopifyApp
  class CarrierServicesManagerJob < ActiveJob::Base
    def perform(shop_domain:, shop_token:)
      ShopifyAPI::Session.temp(shop_domain, shop_token) do
        manager = CarrierServicesManager.new
        manager.create_carrier_services
      end
    end
  end
end
