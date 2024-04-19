# frozen_string_literal: true

module ShopifyApp
  class JWTMiddleware
    TOKEN_REGEX = /^Bearer\s+(.*?)$/
    ID_TOKEN_QUERY_PARAM = "id_token"

    def initialize(app)
      @app = app
    end

    def call(env)
      return call_next(env) unless ShopifyApp.configuration.embedded_app?

      token = token_from_query_string(env) || token_from_authorization_header(env)
      return call_next(env) unless token

      set_env_variables(token, env)
      call_next(env)
    end

    private

    def call_next(env)
      @app.call(env)
    end

    def token_from_authorization_header(env)
      auth_header = env["HTTP_AUTHORIZATION"]
      return unless auth_header

      match = auth_header.match(TOKEN_REGEX)
      match && match[1]
    end

    def token_from_query_string(env)
      Rack::Utils.parse_nested_query(env["QUERY_STRING"])[ID_TOKEN_QUERY_PARAM]
    end

    def set_env_variables(token, env)
      jwt = ShopifyAPI::Auth::JwtPayload.new(token)

      env["jwt.token"] = token
      env["jwt.shopify_domain"] = jwt.shop
      env["jwt.shopify_user_id"] = jwt.sub.to_i
      env["jwt.expire_at"] = jwt.exp
    rescue ShopifyAPI::Errors::InvalidJwtTokenError
      # ShopifyApp::JWT did not raise any exceptions, ensuring behaviour does not change
      nil
    end
  end
end
