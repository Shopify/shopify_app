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

      return head :unauthorized unless hmac_valid?(data)
    end

    def hmac_valid?(data)
      secret = ShopifyApp.configuration.secret
      digest = OpenSSL::Digest.new('sha256')
      ActiveSupport::SecurityUtils.secure_compare(
        shopify_hmac,
        Base64.encode64(OpenSSL::HMAC.digest(digest, secret, data)).strip
      )
    end

    def shop_domain
      request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    end

    def shopify_hmac
      request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    end

  end
end
