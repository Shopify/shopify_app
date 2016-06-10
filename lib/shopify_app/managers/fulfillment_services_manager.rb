module ShopifyApp
  class FulfillmentServicesManager
    class CreationFailed < StandardError; end

    def self.queue(shop_domain, shop_token)
      ShopifyApp::FulfillmentServicesManagerJob.perform_later(shop_domain: shop_domain, shop_token: shop_token)
    end

    def recreate_fulfillment_services!
      destroy_fulfillment_services
      create_fulfillment_services
    end

    def create_fulfillment_services
      return unless required_fulfillment_services.present?

      required_fulfillment_services.each do |fulfillment_services|
        create_fulfillment_service(fulfillment_services) unless fulfillment_services_exists?(fulfillment_services[:name])
      end
    end

    def destroy_fulfillment_services
      ShopifyAPI::FulfillmentService.all.each do |fulfillment_services|
        ShopifyAPI::FulfillmentService.delete(fulfillment_services.id) if is_required_fulfillment_services?(fulfillment_services)
      end

      @current_fulfillment_services = nil
    end

    private

    def required_fulfillment_services
      ShopifyApp.configuration.fulfillment_services
    end

    def is_required_fulfillment_services?(fulfillment_services)
      required_fulfillment_services.map{ |w| w[:name] }.include? fulfillment_services.name
    end

    def create_fulfillment_service(attributes)
      attributes.reverse_merge!(callback_url: callback_url(attributes[:name]), format: 'json')
      fulfillment_services = ShopifyAPI::FulfillmentService.create(attributes)
      raise CreationFailed, fulfillment_services.errors.full_messages.to_sentence unless fulfillment_services.persisted?

      fulfillment_services
    end

    def fulfillment_services_exists?(name)
      current_fulfillment_services[name]
    end

    def current_fulfillment_services
      @current_fulfillment_services ||= ShopifyAPI::FulfillmentService.all.index_by(&:name)
    end

    def callback_url(name)
      File.join(ShopifyApp.configuration.base_url, 'fulfillment_services', name.underscore)
    end
  end
end
