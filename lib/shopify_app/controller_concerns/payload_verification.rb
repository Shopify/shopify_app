# frozen_string_literal: true

module ShopifyApp
  module PayloadVerification
    extend ActiveSupport::Concern

    private

    def shopify_hmac
      shopify_header("hmac-sha256")
    end

    def hmac_valid?(data)
      secrets = [ShopifyApp.configuration.secret, ShopifyApp.configuration.old_secret].reject(&:blank?)

      secrets.any? do |secret|
        digest = OpenSSL::Digest.new("sha256")
        ActiveSupport::SecurityUtils.secure_compare(
          shopify_hmac,
          Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, data)),
        )
      end
    end

    # Retrieves Shopify headers with fallback to legacy format.
    # New headers (shopify-*) take precedence over legacy (X-Shopify-*).
    def shopify_header(name)
      formatted_name = name.upcase.tr("-", "_")
      request.headers["HTTP_SHOPIFY_#{formatted_name}"] || request.headers["HTTP_X_SHOPIFY_#{formatted_name}"]
    end
  end
end
