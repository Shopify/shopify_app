# typed: false
# frozen_string_literal: true

module ShopifyApp
  module WithSessionContext
    include ShopifyApp::SanitizedParams
    extend ActiveSupport::Concern

    def session_token
      @session_token ||= id_token_header || id_token_param
    end

    def id_token_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def id_token_param
      params["id_token"]
    end

    def jwt_shopify_domain
      request.env["jwt.shopify_domain"]
    end

    def jwt_shopify_user_id
      request.env["jwt.shopify_user_id"]
    end

    def jwt_expire_at
      expire_at = request.env["jwt.expire_at"]
      return unless expire_at

      expire_at - 5.seconds # 5s gap to start fetching new token in advance
    end

    def host
      params[:host]
    end

    def current_shopify_domain
      shopify_domain = sanitized_shop_name || current_shopify_session&.shop
      ShopifyApp::Logger.info("Installed store  - #{shopify_domain} deduced from user session")
      shopify_domain
    end

    def current_shopify_session
      @current_shopify_session ||= begin
        cookie_name = ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME
        load_current_session(
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

    def user_session_expected?
      return false if shop_session.nil?
      return false if ShopifyApp.configuration.shop_access_scopes_strategy.update_access_scopes?(shop_session.shop)

      online_token_configured?
    end

    def online_token_configured?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end

    def login_url_with_optional_shop(top_level: false)
      url = ShopifyApp.configuration.login_url

      query_params = login_url_params(top_level: top_level)

      url = "#{url}?#{query_params.to_query}" if query_params.present?
      url
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

    def return_address
      return base_return_address if current_shopify_domain.nil?

      return_address_with_params(shop: current_shopify_domain, host: host)
    rescue ::ShopifyApp::ShopifyDomainNotFound, ::ShopifyApp::ShopifyHostNotFound
      base_return_address
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

    def load_current_session(cookies: nil, is_online: false)
      return ShopifyAPI::Context.load_private_session if ShopifyAPI::Context.private?

      session_id = ShopifyAPI::Utils::SessionUtils.current_session_id(session_token:, cookies:, online: is_online)
      return nil unless session_id

      ShopifyApp::SessionRepository.load_session(session_id)
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
  end
end
