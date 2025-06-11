# frozen_string_literal: true

module ShopifyApp
  module WebhookVerification
    extend ActiveSupport::Concern
    include ShopifyApp::PayloadVerification

    included do
      skip_before_action :verify_authenticity_token, raise: false
      before_action :verify_request
    end

    private

    def verify_request
      request_hash = {
        "method" => request.method,
        "headers" => convert_headers_to_hash(request.headers),
        "body" => request.raw_post,
        "url" => request.original_url,
      }

      config = ShopifyApp.to_shopify_app_ai_config

      auth_result = ::ShopifyApp::AuthWebhook.authenticate(request_hash, config)

      unless auth_result["ok"]
        ShopifyApp::Logger.debug("Webhook verification failed - #{auth_result["action"]}")
        head(:unauthorized)
      end
    end

    def convert_headers_to_hash(headers)
      hash = {}
      headers.each { |key, value| hash[key] = value }
      hash
    end

    def shop_domain
      request.headers["HTTP_X_SHOPIFY_SHOP_DOMAIN"]
    end
  end
end
