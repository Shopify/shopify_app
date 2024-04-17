# frozen_string_literal: true

module ShopifyApp
  module TokenExchange
    extend ActiveSupport::Concern
    include ShopifyApp::AdminAPI::WithTokenRefetch

    INVALID_SHOPIFY_ID_TOKEN_ERRORS = [
      ShopifyAPI::Errors::MissingJwtTokenError,
      ShopifyAPI::Errors::InvalidJwtTokenError,
    ].freeze

    def activate_shopify_session(&block)
      begin
        retrieve_session_from_token_exchange if current_shopify_session.blank? || should_exchange_expired_token?
      rescue *INVALID_SHOPIFY_ID_TOKEN_ERRORS => e
        ShopifyApp::Logger.debug("Responding to invalid Shopify ID token: #{e.message}")
        return respond_to_invalid_shopify_id_token
      end

      begin
        ShopifyApp::Logger.debug("Activating Shopify session")
        ShopifyAPI::Context.activate_session(current_shopify_session)
        with_token_refetch(current_shopify_session, shopify_id_token, &block)
      ensure
        ShopifyApp::Logger.debug("Deactivating session")
        ShopifyAPI::Context.deactivate_session
      end
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
      return if params[:shop].blank?

      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    private

    def retrieve_session_from_token_exchange
      @current_shopify_session = nil
      ShopifyApp::Auth::TokenExchange.perform(shopify_id_token)
    end

    def shopify_id_token
      @shopify_id_token ||= id_token_header
    end

    def id_token_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def respond_to_invalid_shopify_id_token
      return redirect_to_bounce_page if request.headers["HTTP_AUTHORIZATION"].blank?

      ShopifyApp::Logger.debug("Responding to invalid Shopify ID token with unauthorized response")
      response.set_header("X-Shopify-Retry-Invalid-Session-Request", 1)
      unauthorized_response = { message: :unauthorized }
      render(json: { errors: [unauthorized_response] }, status: :unauthorized)
    end

    def redirect_to_bounce_page
      ShopifyApp::Logger.debug("Redirecting to bounce page for patching Shopify ID token")
      patch_shopify_id_token_url = "#{ShopifyApp.configuration.root_url}/patch_shopify_id_token"
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
  end
end
