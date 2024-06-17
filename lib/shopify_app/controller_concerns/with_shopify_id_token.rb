# frozen_string_literal: true

module ShopifyApp
  module WithShopifyIdToken
    extend ActiveSupport::Concern

    def shopify_id_token
      return @shopify_id_token if defined?(@shopify_id_token)

      @shopify_id_token = id_token_from_authorization_header || id_token_from_url_param
    end

    def jwt_payload
      return @jwt_payload if defined?(@jwt_payload)

      @jwt_payload = shopify_id_token.present? ? ShopifyAPI::Auth::JwtPayload.new(shopify_id_token) : nil
    end

    def jwt_shopify_domain
      return @jwt_shopify_domain if defined?(@jwt_shopify_domain)

      @jwt_shopify_domain = if jwt_payload.present?
        ShopifyApp::Utils.sanitize_shop_domain(jwt_payload.shopify_domain)
      end
    end

    def jwt_shopify_user_id
      jwt_payload&.shopify_user_id
    end

    def jwt_expire_at
      expire_at = jwt_payload&.expire_at
      return unless expire_at

      expire_at - 5.seconds # 5s gap to start fetching new token in advance
    end

    private

    def id_token_from_authorization_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def id_token_from_url_param
      params["id_token"]
    end
  end
end
