module ShopifyApp
  module WebhooksController
    extend ActiveSupport::Concern

    included do
      skip_before_action :verify_authenticity_token
      before_action :verify_request
    end

    private

    def verify_request
      request.body.rewind
      data = request.body.read

      unless validate_hmac(ShopifyApp.configuration.secret, data)
        head :unauthorized
      end
    end

    def validate_hmac(secret, data)
      digest  = OpenSSL::Digest.new('sha256')
      shopify_hmac == Base64.encode64(OpenSSL::HMAC.digest(digest, secret, data)).strip
    end

    def shop_domain
      request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    end

    def shopify_hmac
      request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    end

  end
end
