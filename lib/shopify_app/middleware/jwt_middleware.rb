# frozen_string_literal: true

module ShopifyApp
  class JWTMiddleware
    TOKEN_REGEX = /^Bearer\s+(.*?)$/

    def initialize(app)
      @app = app
    end

    def call(env)
      return call_next(env) unless authorization_header(env)

      token = extract_token(env)
      return call_next(env) unless token

      set_env_variables(token, env)
      call_next(env)
    end

    private

    def call_next(env)
      @app.call(env)
    end

    def authorization_header(env)
      env["HTTP_AUTHORIZATION"]
    end

    def extract_token(env)
      match = authorization_header(env).match(TOKEN_REGEX)
      match && match[1]
    end

    def set_env_variables(token, env)
      jwt = ShopifyAPI::Auth::JwtPayload.new(token)

      env["jwt.shopify_domain"] = jwt.shop
      env["jwt.shopify_user_id"] = jwt.sub.to_i
      env["jwt.expire_at"] = jwt.exp
    rescue ShopifyAPI::Errors::InvalidJwtTokenError
      # ShopifyApp::JWT did not raise any exceptions, ensuring behaviour does not change
      nil
    end
  end
end
