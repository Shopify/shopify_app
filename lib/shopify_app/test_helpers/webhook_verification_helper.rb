module ShopifyApp
  module TestHelpers
    module WebhookVerificationHelper
      def authorized_webhook_verification_headers!(params = {})
        digest = OpenSSL::Digest.new('sha256')
        secret = ShopifyApp.configuration.secret
        valid_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, secret, params.to_query)).strip
        @request.headers['HTTP_X_SHOPIFY_HMAC_SHA256'] = valid_hmac
      end

      def unauthorized_webhook_verification_headers!(params = {})
        @request.headers['HTTP_X_SHOPIFY_HMAC_SHA256'] = "invalid_hmac"
      end
    end
  end
end
