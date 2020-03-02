module ShopifyApp
  class SameSiteCookieMiddleware
    COOKIE_SEPARATOR = "\n"

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      user_agent = env['HTTP_USER_AGENT']

      if headers && headers['Set-Cookie'] &&
          BrowserSniffer.new(user_agent).same_site_none_compatible? &&
          ShopifyApp.configuration.enable_same_site_none &&
          Rack::Request.new(env).ssl?

        set_cookies = headers['Set-Cookie']
          .split(COOKIE_SEPARATOR)
          .compact
          .map do |cookie|
            cookie << '; Secure' if not cookie =~ /;\s*secure/i
            cookie << '; SameSite=None' unless cookie =~ /;\s*samesite=/i
            cookie
          end

        headers['Set-Cookie'] = set_cookies.join(COOKIE_SEPARATOR)
      end

      [status, headers, body]
    end
  end
end
