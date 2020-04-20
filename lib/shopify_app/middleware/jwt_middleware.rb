module ShopifyApp
  class JWTMiddleware
    TOKEN_REGEX = /^Bearer\s+(.*?)$/

    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)

      return response unless env['HTTP_AUTHORIZATION']

      match = env['HTTP_AUTHORIZATION'].match(TOKEN_REGEX)
      token = match && match[1]
      return response unless token

      jwt = ShopifyApp::JWT.new(token)

      env['jwt.shopify_domain'] = jwt.shopify_domain
      env['jwt.shopify_user_id'] = jwt.shopify_user_id

      response
    end
  end
end
