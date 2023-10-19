module ShopifyApp
  class OAuthStrategy
    include SanitizedParams

    ACCESS_TOKEN_REQUIRED_HEADER = "X-Shopify-API-Request-Failure-Unauthorized"

    attr_reader :cookies
    delegate :request, :session, :response, :params, :head, :redirect_to, to: :@controller

    def initialize(controller, cookies)
      @controller = controller
      @cookies = cookies
    end

    def activate_shopify_session
      if current_shopify_session.blank?
        signal_access_token_required
        ShopifyApp::Logger.debug("No session found, redirecting to login")
        return redirect_to_login
      end

      if ShopifyApp.configuration.reauth_on_access_scope_changes &&
          !ShopifyApp.configuration.user_access_scopes_strategy.covers_scopes?(current_shopify_session)
        clear_shopify_session
        return redirect_to_login
      end

      begin
        ShopifyApp::Logger.debug("Activating Shopify session")
        ShopifyAPI::Context.activate_session(current_shopify_session)
        yield
      ensure
        ShopifyApp::Logger.debug("Deactivating session")
        ShopifyAPI::Context.deactivate_session
      end
    end

    def start_install
      callback_url = ShopifyApp.configuration.login_callback_url.gsub(%r{^/}, "")
      ShopifyApp::Logger.debug("Starting OAuth with the following callback URL: #{callback_url}")

      auth_attributes = ShopifyAPI::Auth::Oauth.begin_auth(
        shop: sanitized_shop_name,
        redirect_path: "/#{callback_url}",
        is_online: user_session_expected?,
      )
      cookies.encrypted[auth_attributes[:cookie].name] = {
        expires: auth_attributes[:cookie].expires,
        secure: true,
        http_only: true,
        value: auth_attributes[:cookie].value,
      }

      auth_route = auth_attributes[:auth_route]

      ShopifyApp::Logger.debug("Redirecting to auth_route - #{auth_route}")
      redirect_to(auth_route, allow_other_host: true)
    end

    def user_session_expected?
      return false if shop_session.nil?
      return false if ShopifyApp.configuration.shop_access_scopes_strategy.update_access_scopes?(shop_session.shop)

      online_token_configured?
    end

    def current_shopify_session
      @current_shopify_session ||= begin
        cookie_name = ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME
        puts("AUTHORIZATION HEADER: #{request.headers["HTTP_AUTHORIZATION"]}")
        load_current_session(
          auth_header: request.headers["HTTP_AUTHORIZATION"],
          cookies: { cookie_name => cookies.encrypted[cookie_name] },
          is_online: online_token_configured?,
        )
      rescue ShopifyAPI::Errors::CookieNotFoundError
        ShopifyApp::Logger.warn("No cookies have been found - cookie name: #{cookie_name}")
        nil
      rescue ShopifyAPI::Errors::InvalidJwtTokenError
        ShopifyApp::Logger.warn("Invalid JWT token for current Shopify session")
        nil
      end
    end

    def login_again_if_different_user_or_shop
      return unless session_id_conflicts_with_params || session_shop_conflicts_with_params

      ShopifyApp::Logger.debug("Clearing session and redirecting to login")
      clear_shopify_session
      redirect_to_login
    end

    def login_url_with_optional_shop(top_level: false)
      url = ShopifyApp.configuration.login_url

      query_params = login_url_params(top_level: top_level)

      url = "#{url}?#{query_params.to_query}" if query_params.present?
      url
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

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, "true")
    end

    def handle_http_error(error)
      if error.code == 401
        close_session
      else
        raise error
      end
    end

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        raise ::ShopifyApp::ShopifyDomainNotFound if current_shopify_domain.nil?

        render(
          "shopify_app/shared/redirect",
          layout: false,
          locals: { url: url, current_shopify_domain: current_shopify_domain },
        )
      else
        redirect_to(url)
      end
    end

    # Common between strategies
    def current_shopify_domain
      shopify_domain = sanitized_shop_name || current_shopify_session&.shop
      ShopifyApp::Logger.info("Installed store  - #{shopify_domain} deduced from user session")
      shopify_domain
    end

    private

    def shop_session
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(sanitize_shop_param(params))
    end
    
    # Internal
    def close_session
      clear_shopify_session
      ShopifyApp::Logger.debug("Closing session")
      ShopifyApp::Logger.debug("Redirecting to #{login_url_with_optional_shop}")
      redirect_to(login_url_with_optional_shop)
    end

    def online_token_configured?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end

    def load_current_session(auth_header: nil, cookies: nil, is_online: false)
      return ShopifyAPI::Context.load_private_session if ShopifyAPI::Context.private?

      session_id = ShopifyAPI::Utils::SessionUtils.current_session_id(auth_header, cookies, is_online)
      return nil unless session_id

      ShopifyApp::SessionRepository.load_session(session_id)
    end

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

    def host
      params[:host]
    end

    def session_id_conflicts_with_params
      shopify_session_id = current_shopify_session&.shopify_session_id
      params[:session].present? && shopify_session_id.present? && params[:session] != shopify_session_id
    end

    # Internal
    def session_shop_conflicts_with_params
      current_shopify_session && params[:shop].is_a?(String) && current_shopify_session.shop != params[:shop]
    end

    def requested_by_javascript?
      request.xhr? ||
        request.content_type == "text/javascript" ||
        request.content_type == "application/javascript"
    end

    def clear_shopify_session
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = nil
    end

    def login_url_params(top_level:)
      query_params = {}
      query_params[:shop] = sanitized_params[:shop] if params[:shop].present?

      return_to = RedirectSafely.make_safe(session[:return_to] || params[:return_to], nil)

      if return_to.present? && return_to_param_required?
        query_params[:return_to] = return_to
      end

      has_referer_shop_name = referer_sanitized_shop_name.present?

      if has_referer_shop_name
        query_params[:shop] ||= referer_sanitized_shop_name
      end

      if params[:host].present?
        query_params[:host] ||= host
      end

      if params[:access_scopes].present?
        query_params[:scope] = params[:access_scopes].join(",")
      end

      query_params[:top_level] = true if top_level
      query_params
    end

    def return_to_param_required?
      native_params = [:shop, :hmac, :timestamp, :locale, :protocol, :return_to]
      request.path != "/" || sanitized_params.except(*native_params).any?
    end
  end
end