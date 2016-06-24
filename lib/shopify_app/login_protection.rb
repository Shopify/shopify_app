module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveResource::UnauthorizedAccess, :with => :close_session
    end

    def shopify_session
      if shop_session
        begin
          ShopifyAPI::Base.activate_session(shop_session)
          yield
        ensure
          ShopifyAPI::Base.clear_session
        end
      else
        redirect_to_login
      end
    end

    def shop_session
      return unless session[:shopify]
      @shop_session ||= ShopifyApp::SessionRepository.retrieve(session[:shopify])
    end

    def login_again_if_different_shop
      if shop_session && params[:shop] && params[:shop].is_a?(String) && shop_session.url != params[:shop]
        session[:shopify] = nil
        session[:shopify_domain] = nil
        redirect_to_login
      end
    end

    protected

    def redirect_to_login
      if request.xhr?
        head :unauthorized
      else
        session[:return_to] = request.fullpath if request.get?
        redirect_to_with_fallback main_or_engine_login_url(shop: params[:shop])
      end
    end

    def close_session
      session[:shopify] = nil
      session[:shopify_domain] = nil
      redirect_to_with_fallback main_or_engine_login_url(shop: params[:shop])
    end

    def main_or_engine_login_url(params = {})
      main_app.login_url(params)
    rescue NoMethodError => e
      shopify_app.login_url(params)
    end

    def redirect_to_with_fallback(url)
      url_json = url.to_json
      url_json_no_quotes = url_json.gsub(/\A"|"\Z/, '')

      render inline: %Q(
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta http-equiv="refresh" content="1; url=#{url_json_no_quotes}">
            <title>Redirecting…</title>
            <script type="text/javascript">
              window.location.href = #{url_json};
            </script>
          </head>
          <body>
          </body>
        </html>
      ), status: 302, location: url
    end

    def fullpage_redirect_to(url)
      url_json = url.to_json
      url_json_no_quotes = url_json.gsub(/\A"|"\Z/, '')

      if ShopifyApp.configuration.embedded_app?
        render inline: %Q(
          <!DOCTYPE html>
          <html lang="en">
            <head>
              <meta charset="utf-8" />
              <meta http-equiv="refresh" content="1; url=#{url_json_no_quotes}">
              <base target="_top">
              <title>Redirecting…</title>
              <script type="text/javascript">
                window.top.location.href = #{url_json};
              </script>
            </head>
            <body>
            </body>
          </html>
        )
      else
        redirect_to_with_fallback url
      end
    end
  end
end
