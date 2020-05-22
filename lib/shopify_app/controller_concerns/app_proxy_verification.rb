# frozen_string_literal: true
module ShopifyApp
  module AppProxyVerification
    extend ActiveSupport::Concern
    include ShopifyApp::PayloadVerification

    included do
      skip_before_action :verify_authenticity_token, raise: false
      before_action :verify_proxy_request
    end

    def verify_proxy_request
      return head(:forbidden) unless query_string_valid?(request.query_string)
    end

    private

    def query_string_valid?(query_string)
      query_hash = Rack::Utils.parse_query(query_string)

      signature = query_hash.delete('signature')
      return false if signature.nil?

      ActiveSupport::SecurityUtils.secure_compare(
        calculated_signature(query_hash),
        signature
      )
    end
  end
end
