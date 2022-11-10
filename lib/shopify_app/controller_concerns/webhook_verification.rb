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
      data = request.raw_post
      unless hmac_valid?(data)
        ShopifyApp::Logger.debug("Webhook verification failed - HMAC invalid")
        return head(:unauthorized)
      end
    end

    def shop_domain
      request.headers["HTTP_X_SHOPIFY_SHOP_DOMAIN"]
    end
  end
end
