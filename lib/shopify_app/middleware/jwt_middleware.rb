# frozen_string_literal: true

module ShopifyApp
  class JWTMiddleware
    TOKEN_REGEX = /^Bearer\s+(.*?)$/

    def initialize(app)
      @app = app
    end

    def call(env)
      return call_next(env) unless session_token(env)

      token = session_token(env)
      return call_next(env) unless token

      set_env_variables(token, env)
      call_next(env)
    end

    private

    def call_next(env)
      @app.call(env)
    end

    def session_token(env)
      env["HTTP_X_SHOPIFY_SESSION_TOKEN"] || Rack::Request.new(env).params["session_token"]
    end

    def set_env_variables(token, env)
      jwt = ShopifyApp::JWT.new(token)

      env["jwt.shopify_domain"] = jwt.shopify_domain
      env["jwt.shopify_user_id"] = jwt.shopify_user_id
      env["jwt.expire_at"] = jwt.expire_at
    end
  end
end
