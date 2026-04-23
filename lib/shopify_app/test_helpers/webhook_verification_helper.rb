# frozen_string_literal: true

module ShopifyApp
  module TestHelpers
    module WebhookVerificationHelper
      def authorized_webhook_verification_headers!(params = {}, use_new_headers: false)
        digest = OpenSSL::Digest.new("sha256")
        secret = ShopifyApp.configuration.secret
        valid_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, secret, params.to_query)).strip
        header_key = use_new_headers ? "HTTP_SHOPIFY_HMAC_SHA256" : "HTTP_X_SHOPIFY_HMAC_SHA256"
        @request.headers[header_key] = valid_hmac
      end

      def unauthorized_webhook_verification_headers!(use_new_headers: false)
        header_key = use_new_headers ? "HTTP_SHOPIFY_HMAC_SHA256" : "HTTP_X_SHOPIFY_HMAC_SHA256"
        @request.headers[header_key] = "invalid_hmac"
      end
    end
  end
end
