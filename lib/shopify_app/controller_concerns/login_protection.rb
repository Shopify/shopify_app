module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern

    class ShopifyDomainNotFound < StandardError; end

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
      if shop_session && params[:shop] && (shop_session.url != params[:shop])
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
        redirect_to login_url
      end
    end

    def close_session
      session[:shopify] = nil
      session[:shopify_domain] = nil
      redirect_to login_url
    end

    def login_url
      url = ShopifyApp.configuration.login_url

      if params[:shop].present?
        query = { shop: params[:shop] }.to_query
        url = "#{url}?#{query}"
      end

      url
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
            <base target="_top">
            <title>Redirecting…</title>
            <script type="text/javascript">

              // If the current window is the 'parent', change the URL by setting location.href
              if (window.top == window.self) {
                window.top.location.href = #{url.to_json};

              // If the current window is the 'child', change the parent's URL with postMessage
              } else {
                normalizedLink = document.createElement('a');
                normalizedLink.href = #{url.to_json};

                data = JSON.stringify({
                  message: 'Shopify.API.remoteRedirect',
                  data: { location: normalizedLink.href }
                });
                window.parent.postMessage(data, "https://#{current_shopify_domain}");
              }

            </script>
          </head>
          <body>
          </body>
        </html>
      )
    end

    def current_shopify_domain
      shopify_domain = sanitized_shop_name || session[:shopify_domain]
      return shopify_domain if shopify_domain.present?

      raise ShopifyDomainNotFound
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
