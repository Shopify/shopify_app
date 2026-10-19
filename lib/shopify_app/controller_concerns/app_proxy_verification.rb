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

      signature_valid = ActiveSupport::SecurityUtils.secure_compare(
        calculated_signature(query_hash),
        signature,
      )

      signature_valid && timestamp_valid?(query_hash["timestamp"])
    end

    def timestamp_valid?(timestamp)
      tolerance = ShopifyApp.configuration.app_proxy_timestamp_tolerance
      return true if tolerance.nil?
      return false unless timestamp.is_a?(String) && timestamp.match?(/\A\d+\z/)

      (Time.now.to_i - timestamp.to_i).abs <= tolerance
    end

    def calculated_signature(query_hash_without_signature)
      sorted_params = query_hash_without_signature.collect { |k, v| "#{k}=#{Array(v).join(",")}" }.sort.join

      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        ShopifyApp.configuration.secret,
        sorted_params,
      )
    end
  end
end
