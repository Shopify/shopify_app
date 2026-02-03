# frozen_string_literal: true

module ShopifyApp
  module AppProxyVerification
    extend ActiveSupport::Concern
    included do
      skip_before_action :verify_authenticity_token, raise: false
      before_action :verify_proxy_request
    end

    def verify_proxy_request
      head(:forbidden) unless query_string_valid?(request.query_string)
    end

    private

    def query_string_valid?(query_string)
      query_hash = Rack::Utils.parse_query(query_string)

      signature = query_hash.delete("signature")
      return false if signature.nil?

      # Reject requests with array parameters to prevent HMAC signature bypass.
      # Shopify's App Proxy never sends duplicate query parameters, so any array
      # values indicate a potential canonicalization attack where an attacker
      # could swap "ids=1,2" (string) with "ids=1&ids=2" (array) while maintaining
      # the same signature.
      return false if query_hash.values.any? { |v| v.is_a?(Array) }

      ActiveSupport::SecurityUtils.secure_compare(
        calculated_signature(query_hash),
        signature,
      )
    end

    def calculated_signature(query_hash_without_signature)
      sorted_params = query_hash_without_signature.collect { |k, v| "#{k}=#{v}" }.sort.join

      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        ShopifyApp.configuration.secret,
        sorted_params,
      )
    end
  end
end
