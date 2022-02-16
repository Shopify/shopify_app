# frozen_string_literal: true
module ShopifyApp
  class MissingWebhookJobError < StandardError; end

  class WebhooksController < ActionController::Base
    include ShopifyApp::WebhookVerification

    def receive
      params.permit!

      ShopifyAPI::Webhooks::Registry.process(
        ShopifyAPI::Webhooks::Request.new(raw_body: request.raw_post, headers: request.headers.to_h)
      )
      head(:ok)
    end
  end
end
