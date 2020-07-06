# frozen_string_literal: true

module ShopifyApp
  module AccessTokenHeaders
    extend ActiveSupport::Concern

    ACCESS_TOKEN_REQUIRED_HEADER = 'X-Shopify-API-Request-Failure-Unauthorized'

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, true)
    end
  end
end
