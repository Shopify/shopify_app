# frozen_string_literal: true

module ShopifyApp
  module TokenExchange
    extend ActiveSupport::Concern
    include ShopifyApp::AdminAPI::WithTokenRefetch
    include ShopifyApp::SanitizedParams
    include ShopifyApp::EmbeddedApp

    included do
      include ShopifyApp::WithShopifyIdToken
    end

    INVALID_SHOPIFY_ID_TOKEN_ERRORS = [
      ShopifyAPI::Errors::MissingJwtTokenError,
      ShopifyAPI::Errors::InvalidJwtTokenError,
    ].freeze

    def activate_shopify_session(&block)
      retrieve_session_from_token_exchange if current_shopify_session.blank? || should_exchange_expired_token?

      ShopifyApp::Logger.debug("Activating Shopify session")
      ShopifyAPI::Context.activate_session(current_shopify_session)
      with_token_refetch(current_shopify_session, shopify_id_token, &block)
    rescue *INVALID_SHOPIFY_ID_TOKEN_ERRORS => e
      respond_to_invalid_shopify_id_token(e)
    ensure
      ShopifyApp::Logger.debug("Deactivating session")
      ShopifyAPI::Context.deactivate_session
    end

    def should_exchange_expired_token?
      ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
    end

    def current_shopify_session
      return unless current_shopify_session_id

      @current_shopify_session ||= ShopifyApp::SessionRepository.load_session(current_shopify_session_id)
    end

    def current_shopify_session_id
      @current_shopify_session_id ||= ShopifyAPI::Utils::SessionUtils.session_id_from_shopify_id_token(
        id_token: shopify_id_token,
        online: online_token_configured?,
      )
    end

    def current_shopify_domain
      sanitized_shop_name || current_shopify_session&.shop
    rescue *INVALID_SHOPIFY_ID_TOKEN_ERRORS => e
      respond_to_invalid_shopify_id_token(e)
    end

    private

    def retrieve_session_from_token_exchange
      @current_shopify_session = nil
      session = ShopifyApp::Auth::TokenExchange.perform(shopify_id_token)
      ShopifyApp::Logger.debug("Retrieved session: #{session.inspect}")
      @current_shopify_session = session
    end

    def respond_to_invalid_shopify_id_token(error)
      ShopifyApp::Logger.debug("Responding to invalid Shopify ID token: #{error.message}")
      return if performed?

      if request.headers["HTTP_AUTHORIZATION"].blank?
        if embedded?
          redirect_to_bounce_page
        else
          redirect_to_embed_app_in_admin
        end
      else
        ShopifyApp::Logger.debug("Responding to invalid Shopify ID token with unauthorized response")
        response.set_header("X-Shopify-Retry-Invalid-Session-Request", 1)
        unauthorized_response = { message: :unauthorized }
        render(json: { errors: [unauthorized_response] }, status: :unauthorized)
      end
    end

    def redirect_to_bounce_page
      ShopifyApp::Logger.debug("Redirecting to bounce page for patching Shopify ID token")
      patch_shopify_id_token_url =
        "#{ShopifyAPI::Context.host}#{ShopifyApp.configuration.root_url}/patch_shopify_id_token"
      patch_shopify_id_token_params = request.query_parameters.except(:id_token)

      bounce_url = "#{request.path}?#{patch_shopify_id_token_params.to_query}"

      # App Bridge will trigger a fetch to the URL in shopify-reload, with a new session token in headers
      patch_shopify_id_token_params["shopify-reload"] = bounce_url

      redirect_to(
        "#{patch_shopify_id_token_url}?#{patch_shopify_id_token_params.to_query}",
        allow_other_host: true,
      )
    end

    def online_token_configured?
      ShopifyApp.configuration.online_token_configured?
    end

    def fullpage_redirect_to(url)
      raise ShopifyApp::ShopifyDomainNotFound if current_shopify_domain.nil?

      render(
        "shopify_app/shared/redirect",
        layout: false,
        locals: { url: url, current_shopify_domain: current_shopify_domain, is_iframe: embedded? },
      )
    end
  end
end
