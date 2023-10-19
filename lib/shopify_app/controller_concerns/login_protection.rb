# frozen_string_literal: true

require "browser_sniffer"

module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern
    include ShopifyApp::SanitizedParams

    included do
      if defined?(ShopifyApp::RequireKnownShop) &&
          defined?(ShopifyApp::EnsureInstalled) &&
          ancestors.include?(ShopifyApp::RequireKnownShop || ShopifyApp::EnsureInstalled)
        message = <<~EOS
          We detected the use of incompatible concerns (RequireKnownShop/EnsureInstalled and LoginProtection) in #{name},
          which may lead to unpredictable behavior. In a future release of this library this will raise an error.
        EOS
        ShopifyApp::Logger.deprecated(message, "22.0.0")
      end

      rescue_from ShopifyAPI::Errors::HttpResponseError, with: :handle_http_error
    end

    ACCESS_TOKEN_REQUIRED_HEADER = "X-Shopify-API-Request-Failure-Unauthorized"

    # External
    def activate_shopify_session(&block)
      auth_strategy.activate_shopify_session(&block)
    end

    def auth_strategy
      @auth_strategy ||= ShopifyApp::OAuthStrategy.new(self, cookies)
    end

    # External
    def current_shopify_session
      auth_strategy.current_shopify_session
    end

    # External
    def login_again_if_different_user_or_shop
      auth_strategy.login_again_if_different_user_or_shop
    end

    # Should be private
    def signal_access_token_required
      auth_strategy.signal_access_token_required
    end

    # Not used anywhere
    def jwt_expire_at
      expire_at = request.env["jwt.expire_at"]
      return unless expire_at

      expire_at - 5.seconds # 5s gap to start fetching new token in advance
    end

    # External
    def add_top_level_redirection_headers(url: nil, ignore_response_code: false)
      auth_strategy.add_top_level_redirection_headers(url: url, ignore_response_code: ignore_response_code)
    end

    protected

    # External
    def jwt_shopify_domain
      request.env["jwt.shopify_domain"]
    end

    # Not used (seemingly)
    def jwt_shopify_user_id
      request.env["jwt.shopify_user_id"]
    end

    def host
      params[:host]
    end

    # External
    def redirect_to_login
      auth_strategy.redirect_to_login
    end

    # Internal
    def handle_http_error(error)
      auth_strategy.handle_http_error(error)
    end

    # External
    def login_url_with_optional_shop(top_level: false)
      auth_strategy.login_url_with_optional_shop(top_level: top_level)
    end

    # External
    def fullpage_redirect_to(url)
      auth_strategy.fullpage_redirect_to(url)
    end

    # External
    def current_shopify_domain
      auth_strategy.current_shopify_domain
    end

    # External
    def return_address
      return base_return_address if current_shopify_domain.nil?

      return_address_with_params(shop: current_shopify_domain, host: host)
    rescue ::ShopifyApp::ShopifyDomainNotFound, ::ShopifyApp::ShopifyHostNotFound
      base_return_address
    end

    # Internal
    def base_return_address
      session.delete(:return_to) || ShopifyApp.configuration.root_url
    end

    # Internal
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

    # Internal
    def shop_session
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(sanitize_shop_param(params))
    end

    # Internal
    def online_token_configured?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end

    # External
    def user_session_expected?
      auth_strategy.user_session_expected?
    end
  end
end
