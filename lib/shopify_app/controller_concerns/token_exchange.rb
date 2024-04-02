# frozen_string_literal: true

module ShopifyApp
  module TokenExchange
    extend ActiveSupport::Concern

    def activate_shopify_session
      if current_shopify_session.blank?
        retrieve_session_from_token_exchange
      end

      if ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
        retrieve_session_from_token_exchange
      end

      attempts = 0
      begin
        ShopifyApp::Logger.debug("Activating Shopify session")
        ShopifyAPI::Context.activate_session(current_shopify_session)
        yield
      rescue ShopifyAPI::Errors::HttpResponseError => error
        if error.code == 401 && attempts.zero?
          ShopifyApp::Logger.debug("Encountered 401 error, exchanging token and retrying with new access token")
          attempts += 1
          retrieve_session_from_token_exchange
          retry
        else
          ShopifyApp::Logger.debug("Encountered error: #{error.code} - #{error.message}, re-raising")
          raise
        end
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
      @current_shopify_session = nil
      # TODO: Right now JWT Middleware only updates env['jwt.shopify_domain'] from request headers tokens,
      # which won't work for new installs.
      # we need to update the middleware to also update the env['jwt.shopify_domain'] from the query params
      domain = ShopifyApp::JWT.new(session_token).shopify_domain

      ShopifyApp::Logger.info("Performing Token Exchange for [#{domain}] - (Offline)")
      session = exchange_token(
        shop: domain, # TODO: use jwt_shopify_domain ?
        session_token: session_token,
        requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
      )

      if session && online_token_configured?
        ShopifyApp::Logger.info("Performing Token Exchange for [#{domain}] - (Online)")
        session = exchange_token(
          shop: domain, # TODO: use jwt_shopify_domain ?
          session_token: session_token,
          requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
        )
      end

      ShopifyApp.configuration.post_authenticate_tasks.perform(session)
    end

    def exchange_token(shop:, session_token:, requested_token_type:)
      if session_token.blank?
        # respond_to_invalid_session_token
        return
      end

      begin
        session = ShopifyAPI::Auth::TokenExchange.exchange_token(
          shop: shop,
          session_token: session_token,
          requested_token_type: requested_token_type,
        )
      rescue ShopifyAPI::Errors::InvalidJwtTokenError
        # respond_to_invalid_session_token
        return
      rescue ShopifyAPI::Errors::HttpResponseError => error
        ShopifyApp::Logger.error(
          "A #{error.code} error (#{error.class}) occurred during the token exchange. Response: #{error.response.body}",
        )
        raise
      rescue => error
        ShopifyApp::Logger.error("An error occurred during the token exchange: #{error.message}")
        raise
      end

      if session
        begin
          ShopifyApp::SessionRepository.store_session(session)
        rescue ActiveRecord::RecordNotUnique
          ShopifyApp::Logger.debug("Session not stored due to concurrent token exchange calls")
        end
      end

      session
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
