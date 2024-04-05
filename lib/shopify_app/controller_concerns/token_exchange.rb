# frozen_string_literal: true

module ShopifyApp
  module TokenExchange
    extend ActiveSupport::Concern

    def activate_shopify_session
      if current_shopify_session.blank?
        retrieve_session_from_token_exchange
      end

      if ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
        @current_shopify_session = nil
        retrieve_session_from_token_exchange
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
        session_id = ShopifyAPI::Utils::SessionUtils.current_session_id(
          request.headers["HTTP_AUTHORIZATION"],
          nil,
          online_token_configured?,
        )
        return nil unless session_id

        ShopifyApp::SessionRepository.load_session(session_id)
      end
    end

    def current_shopify_domain
      return if params[:shop].blank?

      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    private

    def retrieve_session_from_token_exchange
      # TODO: Right now JWT Middleware only updates env['jwt.shopify_domain'] from request headers tokens,
      # which won't work for new installs.
      # we need to update the middleware to also update the env['jwt.shopify_domain'] from the query params
      ShopifyApp::Auth::TokenExchange.perform(session_token)
      # TODO: Rescue JWT validation errors when bounce page is ready
      # rescue ShopifyAPI::Errors::InvalidJwtTokenError
      #   respond_to_invalid_session_token
    end

    def session_token
      @session_token ||= id_token_header
    end

    def id_token_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def respond_to_invalid_session_token
      # TODO: Implement this method to handle invalid session tokens

      # if request.xhr?
      # response.set_header("X-Shopify-Retry-Invalid-Session-Request", 1)
      # unauthorized_response = { message: :unauthorized }
      # render(json: { errors: [unauthorized_response] }, status: :unauthorized)
      # else
      # patch_session_token_url = "#{ShopifyAPI::Context.host}/patch_session_token"
      # patch_session_token_params = request.query_parameters.except(:id_token)

      # bounce_url = "#{ShopifyAPI::Context.host}#{request.path}?#{patch_session_token_params.to_query}"

      # # App Bridge will trigger a fetch to the URL in shopify-reload, with a new session token in headers
      # patch_session_token_params["shopify-reload"] = bounce_url

      # redirect_to("#{patch_session_token_url}?#{patch_session_token_params.to_query}", allow_other_host: true)
      # end
    end

    def online_token_configured?
      ShopifyApp.configuration.online_token_configured?
    end
  end
end
