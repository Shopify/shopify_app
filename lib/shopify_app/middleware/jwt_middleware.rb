# frozen_string_literal: true
module ShopifyApp
  class JWTMiddleware
    TOKEN_REGEX = /^Bearer\s+(.*?)$/

    def initialize(app)
      @app = app
    end

    def call(env)
      byebug
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
      env['HTTP_AUTHORIZATION']
    end

    def extract_token(env)
      match = authorization_header(env).match(TOKEN_REGEX)
      match && match[1]
    end

    def set_env_variables(token, env)
      jwt = ShopifyApp::JWT.new(token)

      env['jwt.shopify_domain'] = jwt.shopify_domain
      env['jwt.shopify_user_id'] = jwt.shopify_user_id
      env['jwt.shopify_session_id'] = jwt.shopify_session_id
    end
  end
end
