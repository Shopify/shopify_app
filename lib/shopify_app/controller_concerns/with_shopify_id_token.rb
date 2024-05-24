# frozen_string_literal: true

module ShopifyApp
  module WithShopifyIdToken
    extend ActiveSupport::Concern

    def shopify_id_token
      @shopify_id_token ||= id_token_from_request_env || id_token_from_authorization_header || id_token_from_url_param
    end

    def jwt_shopify_domain
      request.env["jwt.shopify_domain"]
    end

    def jwt_shopify_user_id
      request.env["jwt.shopify_user_id"]
    end

    def jwt_expire_at
      expire_at = request.env["jwt.expire_at"]
      return unless expire_at

      expire_at - 5.seconds # 5s gap to start fetching new token in advance
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
