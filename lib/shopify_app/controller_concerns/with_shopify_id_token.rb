# frozen_string_literal: true

module ShopifyApp
  module WithShopifyIdToken
    extend ActiveSupport::Concern

    def shopify_id_token
      @shopify_id_token ||= id_token_from_request_env || id_token_from_authorization_header || id_token_from_url_param
    end

    private

    def id_token_from_request_env
      # This is set from ShopifyApp::JWTMiddleware
      request.env["jwt.token"]
    end

    def id_token_from_authorization_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def id_token_from_url_param
      params["id_token"]
    end
  end
end
