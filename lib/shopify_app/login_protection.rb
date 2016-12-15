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
        redirect_to main_or_engine_login_url(shop: params[:shop])
      end
    end

    def close_session
      session[:shopify] = nil
      session[:shopify_domain] = nil
      redirect_to main_or_engine_login_url(shop: params[:shop])
    end

    def main_or_engine_login_url(params = {})
      main_app.login_url(params)
    rescue NoMethodError
      shopify_app.login_url(params)
    end

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        render inline: redirection_javascript(url)
      else
        redirect_to url
      end
    end

    def redirection_javascript(url)
      %(
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <title>Redirecting…</title>
            <script type="text/javascript">
              data = JSON.stringify({
                message: 'Shopify.API.remoteRedirect',
                data: { location: window.location.origin + #{url.to_json} }
              });
              window.parent.postMessage(data, "https://#{sanitized_shop_name}");
            </script>
          </head>
          <body>
          </body>
        </html>
      )
    end

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

    def sanitize_shop_param(params)
      return unless params[:shop].present?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

  end
end
