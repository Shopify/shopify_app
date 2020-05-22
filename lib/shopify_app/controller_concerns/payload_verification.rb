# frozen_string_literal: true
module ShopifyApp
  module PayloadVerification
    extend ActiveSupport::Concern

    def hmac_valid?(data)
      secrets = [ShopifyApp.configuration.secret, ShopifyApp.configuration.old_secret].reject(&:blank?)

      secrets.any? do |secret|
        digest = OpenSSL::Digest.new('sha256')

        ActiveSupport::SecurityUtils.secure_compare(
          shopify_hmac,
          Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, data))
        )
      end
    end

    def shopify_hmac
      request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    end
  end
end
