# frozen_string_literal: true

module ShopifyApp
  module AccessTokenHeaders
    extend ActiveSupport::Concern

    included do
      after_action(:set_access_token_headers)
    end

    ACCESS_TOKEN_REQUIRED_HEADER = 'X-Shopify-Request-Auth-Code'

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, true)
    end

    private

    def set_access_token_headers
      if response.get_header(ACCESS_TOKEN_REQUIRED_HEADER).nil?
        response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, false)
      end
    end
  end
end
