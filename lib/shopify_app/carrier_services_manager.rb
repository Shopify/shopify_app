module ShopifyApp
  class CarrierServicesManager
    class CreationFailed < StandardError; end

    def self.queue(shop_domain, shop_token)
      ShopifyApp::CarrierServicesManagerJob.perform_later(shop_domain: shop_domain, shop_token: shop_token)
    end

    def recreate_carrier_services!
      destroy_carrier_services
      create_carrier_services
    end

    def create_carrier_services
      return unless required_carrier_services.present?

      required_carrier_services.each do |carrier_service|
        create_carrier_service(carrier_service) unless carrier_service_exists?(carrier_service[:name])
      end
    end

    def destroy_carrier_services
      ShopifyAPI::CarrierService.all.each do |carrier_service|
        ShopifyAPI::CarrierService.delete(carrier_service.id) if is_required_carrier_service?(carrier_service)
      end

      @current_carrier_services = nil
    end

    private

    def required_carrier_services
      ShopifyApp.configuration.carrier_services
    end

    def is_required_carrier_service?(carrier_service)
      required_carrier_services.map{ |w| w[:name] }.include? carrier_service.name
    end

    def create_carrier_service(attributes)
      attributes.reverse_merge!(format: 'json')
      carrier_service = ShopifyAPI::CarrierService.create(attributes)
      raise CreationFailed, carrier_service.errors.full_messages.to_sentence unless carrier_service.persisted?
      carrier_service
    end

    def carrier_service_exists?(name)
      current_carrier_services[name]
    end

    def current_carrier_services
      @current_carrier_services ||= ShopifyAPI::CarrierService.all.index_by(&:name)
    end
  end
end
