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

      @jwt_payload = if shopify_id_token.present?
        # Use the gem's Utils to validate and decode the token
        ::ShopifyApp::Utils.validate_jwt_token(
          shopify_id_token,
          ShopifyApp.configuration.secret,
          clock_tolerance: 10,
        )
      end
    end

    def jwt_shopify_domain
      return @jwt_shopify_domain if defined?(@jwt_shopify_domain)

      @jwt_shopify_domain = if jwt_payload.present?
        shop = jwt_payload["dest"]&.gsub(%r{^https://}, "")
        ::ShopifyApp::Utils.sanitize_shop_domain(shop)
      end
    end

    def jwt_shopify_user_id
      jwt_payload&.dig("sub")
    end

    def jwt_expire_at
      return unless jwt_payload&.dig("exp")

      expire_at = Time.at(jwt_payload["exp"])
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
