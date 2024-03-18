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
  end
end
