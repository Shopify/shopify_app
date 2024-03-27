# frozen_string_literal: true

module ShopifyApp
  module JWTParser
    extend ActiveSupport::Concern

    TOKEN_REGEX = /^Bearer\s+(.*?)$/

    included do
      before_action :ensure_shopify_jwt_parsed
    end

    def ensure_shopify_jwt_parsed
      return if @ensure_shopify_jwt_parsed

      @ensure_shopify_jwt_parsed = true
      env = request.env

      authorization_header = env["HTTP_AUTHORIZATION"]
      return unless authorization_header

      token = authorization_header(env).match(TOKEN_REGEX)&.[](1)
      return unless token

      jwt = ShopifyApp::JWT.new(token)

      env["jwt.shopify_domain"] = jwt.shopify_domain
      env["jwt.shopify_user_id"] = jwt.shopify_user_id
      env["jwt.expire_at"] = jwt.expire_at
    end
  end
end
