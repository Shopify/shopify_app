# frozen_string_literal: true

module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern
    include ShopifyApp::SanitizedParams

    included do
      include ShopifyApp::WithSessionContext
      include ShopifyApp::AuthorizationStrategy

      if defined?(ShopifyApp::EnsureInstalled) &&
          ancestors.include?(ShopifyApp::EnsureInstalled)
        message = <<~EOS
          We detected the use of incompatible concerns (EnsureInstalled and LoginProtection) in #{name},
          which leads to unpredictable behavior. You cannot include both concerns in the same controller.
        EOS
        raise message
      end

      rescue_from ShopifyAPI::Errors::HttpResponseError, with: :handle_http_error
    end

    def activate_shopify_session
      return unless authenticate_session

      begin
        ShopifyApp::Logger.debug("Activating Shopify session")
        ShopifyAPI::Context.activate_session(current_shopify_session)
        yield
      ensure
        ShopifyApp::Logger.debug("Deactivating session")
        ShopifyAPI::Context.deactivate_session
      end
    end

    def login_again_if_different_user_or_shop
      return unless session_id_conflicts_with_params || session_shop_conflicts_with_params

      ShopifyApp::Logger.debug("Clearing session and redirecting to login")
      clear_shopify_session
      redirect_to_login
    end

    def add_top_level_redirection_headers(url: nil, ignore_response_code: false)
      if request.xhr? && (ignore_response_code || response.code.to_i == 401)
        ShopifyApp::Logger.debug("Adding top level redirection headers")
        # Make sure the shop is set in the redirection URL
        unless params[:shop]
          ShopifyApp::Logger.debug("Setting current shop session")
          params[:shop] = if current_shopify_session
            current_shopify_session.shop

          elsif (matches = request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/))
            jwt_payload = ShopifyAPI::Auth::JwtPayload.new(T.must(matches[1]))
            jwt_payload.shop
          end
        end

        url ||= login_url_with_optional_shop

        ShopifyApp::Logger.debug("Setting Reauthorize-Url to #{url}")
        response.set_header("X-Shopify-API-Request-Failure-Reauthorize", "1")
        response.set_header("X-Shopify-API-Request-Failure-Reauthorize-Url", url)
      end
    end

    protected

    def redirect_to_login
      if requested_by_javascript?
        add_top_level_redirection_headers(ignore_response_code: true)
        ShopifyApp::Logger.debug("Login redirect request is a XHR")
        head(:unauthorized)
      else
        if request.get?
          path = request.path
          query = sanitized_params.to_query
        else
          referer = URI(request.referer || "/")
          path = referer.path
          query = Rack::Utils.parse_nested_query(referer.query)
          query = query.merge(sanitized_params).to_query
        end
        session[:return_to] = query.blank? ? path.to_s : "#{path}?#{query}"
        ShopifyApp::Logger.debug("Redirecting to #{login_url_with_optional_shop}")
        redirect_to(login_url_with_optional_shop)
      end
    end

    def close_session
      ShopifyApp::Logger.debug("Closing session")
      clear_shopify_session

      ShopifyApp::Logger.debug("Redirecting to login")
      redirect_to_login
    end

    def handle_http_error(error)
      if error.code == 401
        close_session
      else
        raise error
      end
    end

    def clear_shopify_session
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = nil
    end

    private

    def requested_by_javascript?
      request.xhr? ||
        request.media_type == "text/javascript" ||
        request.media_type == "application/javascript"
    end
  end
end
