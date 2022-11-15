# frozen_string_literal: true

require "browser_sniffer"

module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern
    include ShopifyApp::Itp
    include ShopifyApp::SanitizedParams

    included do
      if ancestors.include?(ShopifyApp::RequireKnownShop)
        ShopifyApp::Logger.deprecated(<<~EOS)
          We detected the use of incompatible concerns (RequireKnownShop and LoginProtection) in #{name},
          which may lead to unpredictable behavior. In a future release of this library this will raise an error.
        EOS
      end

      after_action :set_test_cookie
      rescue_from ShopifyAPI::Errors::HttpResponseError, with: :handle_http_error
    end

    ACCESS_TOKEN_REQUIRED_HEADER = "X-Shopify-API-Request-Failure-Unauthorized"

    def activate_shopify_session
      if current_shopify_session.blank?
        signal_access_token_required
        ShopifyApp::Logger.debug("No session found, redirecting to login")
        return redirect_to_login
      end

      unless current_shopify_session.scope.to_a.empty? ||
          current_shopify_session.scope.covers?(ShopifyAPI::Context.scope)

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

    def current_shopify_session
      @current_shopify_session ||= begin
        cookie_name = ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME
        ShopifyAPI::Utils::SessionUtils.load_current_session(
          auth_header: request.headers["HTTP_AUTHORIZATION"],
          cookies: { cookie_name => cookies.encrypted[cookie_name] },
          is_online: online_token_configured?,
        )
      rescue ShopifyAPI::Errors::CookieNotFoundError
        ShopifyApp::Logger.info("No cookies have been found - cookie name: #{cookie_name}")
        nil
      rescue ShopifyAPI::Errors::InvalidJwtTokenError
        ShopifyApp::Logger.info("Invalid JWT token for current Shopify session")
        nil
      end
    end

    def login_again_if_different_user_or_shop
      return unless session_id_conflicts_with_params || session_shop_conflicts_with_params

      ShopifyApp::Logger.debug("Clearing session and redirecting to login")
      clear_shopify_session
      redirect_to_login
    end

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, "true")
    end

    def jwt_expire_at
      expire_at = request.env["jwt.expire_at"]
      return unless expire_at

      expire_at - 5.seconds # 5s gap to start fetching new token in advance
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

    def jwt_shopify_domain
      request.env["jwt.shopify_domain"]
    end

    def jwt_shopify_user_id
      request.env["jwt.shopify_user_id"]
    end

    def host
      params[:host]
    end

    def redirect_to_login
      if request.xhr?
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
      clear_shopify_session
      ShopifyApp::Logger.debug("Closing session")
      ShopifyApp::Logger.debug("Redirecting to #{login_url_with_optional_shop}")
      redirect_to(login_url_with_optional_shop)
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

    def login_url_with_optional_shop(top_level: false)
      url = ShopifyApp.configuration.login_url

      query_params = login_url_params(top_level: top_level)

      url = "#{url}?#{query_params.to_query}" if query_params.present?
      url
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

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        render("shopify_app/shared/redirect", layout: false,
          locals: { url: url, current_shopify_domain: current_shopify_domain })
      else
        redirect_to(url)
      end
    end

    def current_shopify_domain
      shopify_domain = sanitized_shop_name || current_shopify_session&.shop

      return shopify_domain if shopify_domain.present?

      raise ::ShopifyApp::ShopifyDomainNotFound
    end

    def return_address
      return_address_with_params(shop: current_shopify_domain, host: host)
    rescue ::ShopifyApp::ShopifyDomainNotFound, ::ShopifyApp::ShopifyHostNotFound
      base_return_address
    end

    def base_return_address
      session.delete(:return_to) || ShopifyApp.configuration.root_url
    end

    def return_address_with_params(params)
      uri = URI(base_return_address)
      uri.query = CGI.parse(uri.query.to_s)
        .symbolize_keys
        .transform_values { |v| v.one? ? v.first : v }
        .merge(params)
        .to_query
      uri.to_s
    end

    private

    def session_id_conflicts_with_params
      shopify_session_id = current_shopify_session&.shopify_session_id
      params[:session].present? && shopify_session_id.present? && params[:session] != shopify_session_id
    end

    def session_shop_conflicts_with_params
      current_shopify_session && params[:shop].is_a?(String) && current_shopify_session.shop != params[:shop]
    end

    def shop_session
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(sanitize_shop_param(params))
    end

    def online_token_configured?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end

    def user_session_expected?
      return false if shop_session.nil?
      return false if ShopifyApp.configuration.shop_access_scopes_strategy.update_access_scopes?(shop_session.shop)

      online_token_configured?
    end
  end
end
