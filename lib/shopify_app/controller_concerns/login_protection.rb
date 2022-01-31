# frozen_string_literal: true

require 'browser_sniffer'

module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern
    include ShopifyApp::Itp

    class ShopifyDomainNotFound < StandardError; end

    class ShopifyHostNotFound < StandardError; end

    included do
      after_action :set_test_cookie
      rescue_from ActiveResource::UnauthorizedAccess, with: :close_session
    end

    ACCESS_TOKEN_REQUIRED_HEADER = 'X-Shopify-API-Request-Failure-Unauthorized'

    def activate_shopify_session
      if user_session_expected? && user_session.blank?
        signal_access_token_required
        return redirect_to_login
      end

      return redirect_to_login if current_shopify_session.blank?

      clear_top_level_oauth_cookie

      begin
        ShopifyAPI::Base.activate_session(current_shopify_session)
        yield
      ensure
        ShopifyAPI::Base.clear_session
      end
    end

    def current_shopify_session
      @current_shopify_session ||= begin
        user_session || shop_session
      end
    end

    def user_session
      user_session_by_jwt || user_session_by_cookie
    end

    def user_session_by_jwt
      return unless ShopifyApp.configuration.allow_jwt_authentication
      return unless jwt_shopify_user_id
      ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(jwt_shopify_user_id)
    end

    def user_session_by_cookie
      return unless ShopifyApp.configuration.allow_cookie_authentication
      return unless session[:user_id].present?
      ShopifyApp::SessionRepository.retrieve_user_session(session[:user_id])
    end

    def shop_session
      shop_session_by_jwt || shop_session_by_cookie
    end

    def shop_session_by_jwt
      return unless ShopifyApp.configuration.allow_jwt_authentication
      return unless jwt_shopify_domain
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(jwt_shopify_domain)
    end

    def shop_session_by_cookie
      return unless ShopifyApp.configuration.allow_cookie_authentication
      return unless session[:shop_id].present?
      ShopifyApp::SessionRepository.retrieve_shop_session(session[:shop_id])
    end

    def login_again_if_different_user_or_shop
      if session[:user_session].present? && params[:session].present? # session data was sent/stored correctly
        clear_session = session[:user_session] != params[:session] # current user is different from stored user
      end

      if current_shopify_session &&
        params[:shop] && params[:shop].is_a?(String) &&
        (current_shopify_session.domain != params[:shop])
        clear_session = true
      end

      if clear_session
        clear_shopify_session
        redirect_to_login
      end
    end

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, "true")
    end

    def jwt_expire_at
      expire_at = request.env['jwt.expire_at']
      return unless expire_at
      expire_at - 5.seconds # 5s gap to start fetching new token in advance
    end

    protected

    def jwt_shopify_domain
      request.env['jwt.shopify_domain']
    end

    def jwt_shopify_user_id
      request.env['jwt.shopify_user_id']
    end

    def host
      return params[:host] if params[:host].present?

      raise ShopifyHostNotFound
    end

    def redirect_to_login
      if request.xhr?
        head(:unauthorized)
      else
        if request.get?
          path = request.path
          query = sanitized_params.to_query
        else
          referer = URI(request.referer || "/")
          path = referer.path
          query = "#{referer.query}&#{sanitized_params.to_query}"
        end
        session[:return_to] = query.blank? ? path.to_s : "#{path}?#{query}"
        redirect_to(login_url_with_optional_shop)
      end
    end

    def close_session
      clear_shopify_session
      redirect_to(login_url_with_optional_shop)
    end

    def clear_shopify_session
      session[:shop_id] = nil
      session[:user_id] = nil
      session[:shopify_domain] = nil
      session[:shopify_user] = nil
      session[:user_session] = nil
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

      query_params[:top_level] = true if top_level
      query_params
    end

    def return_to_param_required?
      native_params = %i[shop hmac timestamp locale protocol return_to]
      request.path != '/' || sanitized_params.except(*native_params).any?
    end

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        render('shopify_app/shared/redirect', layout: false,
               locals: { url: url, current_shopify_domain: current_shopify_domain })
      else
        redirect_to(url)
      end
    end

    def current_shopify_domain
      shopify_domain = sanitized_shop_name ||
        jwt_shopify_domain ||
        session[:shopify_domain]

      return shopify_domain if shopify_domain.present?

      raise ShopifyDomainNotFound
    end

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

    def referer_sanitized_shop_name
      return unless request.referer.present?

      @referer_sanitized_shop_name ||= begin
        referer_uri = URI(request.referer)
        query_params = Rack::Utils.parse_query(referer_uri.query)

        sanitize_shop_param(query_params.with_indifferent_access)
      end
    end

    def sanitize_shop_param(params)
      return unless params[:shop].present?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def sanitized_params
      request.query_parameters.clone.tap do |query_params|
        if params[:shop].is_a?(String)
          query_params[:shop] = sanitize_shop_param(params)
        end
      end
    end

    def return_address
      return_address_with_params(shop: current_shopify_domain, host: host)
    rescue ShopifyDomainNotFound, ShopifyHostNotFound
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

    def user_session_expected?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end
  end
end
