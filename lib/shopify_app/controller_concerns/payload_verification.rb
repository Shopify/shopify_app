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

    def verify_request
      hmac_header = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
      request_body = request.body.read
      secret = ShopifyApp.configuration.secret
      digest = OpenSSL::Digest.new('sha256')

      expected_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, request_body))
      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(expected_hmac, hmac_header)
    end

    def calculated_signature(query_hash_without_signature)
      sorted_params = query_hash_without_signature.collect { |k, v| "#{k}=#{Array(v).join(',')}" }.sort.join

      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('sha256'),
        ShopifyApp.configuration.secret,
        sorted_params
      )
    end
  end
end
