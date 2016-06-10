module ShopifyApp
  class FulfillmentServicesController < ApplicationController
    class ShopifyApp::MissingFulfillmentServiceError < StandardError; end

    def action_missing(name)
      render json: fulfillment_service_klass.send(name, fulfilment_service_params)
    end

    private

    def fulfilment_service_params
      params.except(:controller, :action)
    end

    def fulfillment_service_klass
      "#{fulfillment_service_name.classify}FulfillmentService".safe_constantize or raise ShopifyApp::MissingFulfillmentServiceError
    end

    def fulfillment_service_name
      params[:name]
    end
  end
end
