# frozen_string_literal: true

module ShopifyApp
  module RetrieveSessionFromTokenExchange
    extend ActiveSupport::Concern

    def activate_shopify_session
     if current_shopify_session.blank?
       retrieve_session_from_token_exchange
      end

      if ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
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

    def login_again_if_different_user_or_shop

    end

    def add_top_level_redirection_headers
    end

    private

    def retrieve_session_from_token_exchange
        # TODO: Right now JWT Middleware only updates env['jwt.shopify_domain'] from request headers tokens, which won't work for new installs
        # We need to update the middleware to also update the env['jwt.shopify_domain'] from the query params
        @curent_shopify_session = nil
        domain = ShopifyApp::JWT.new(session_token).shopify_domain

        session = exchange_token(
          shop: domain, # TODO: use jwt_shopify_domain ?
          session_token: session_token,
          requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
        )

        if session && online_token_configured?
          session = exchange_token(
            shop: domain, # TODO: use jwt_shopify_domain ?
            session_token: session_token,
            requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
          )
        end

        #ShopifyApp::configuration.post_authenticate_tasks.perform(session) if session
    end

    def exchange_token(shop:, session_token:, requested_token_type:)
      if session_token.blank?
        #respond_to_invalid_session_token
        return
      end

      begin
        session = ShopifyAPI::Auth::TokenExchange.exchange_token(
          shop: shop,
          session_token: session_token,
          requested_token_type: requested_token_type,
        )
      rescue ShopifyAPI::Errors::InvalidJwtTokenError
        #respond_to_invalid_session_token
        return
      rescue ShopifyAPI::Errors::HttpResponseError => error
        ShopifyApp::Logger.info("A #{error.code} error (#{error.class.to_s}) occurred during the token exchange. Response: #{error.response.body}")
        raise
      rescue => error
        ShopifyApp::Logger.info("An error occurred during the token exchange: #{error.message}")
        raise
      end

      if session
        begin
          ShopifyApp::SessionRepository.store_session(session)
        rescue ActiveRecord::RecordNotUnique
          ShopifyApp::Logger.debug("Session not stored due to concurrent token exchange calls")
        end
      end

      return session
    end

    def session_token
      @session_token ||= id_token_header
    end

    def id_token_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def online_token_configured?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end

    def current_shopify_session
      @curent_shopify_session ||= begin
        session_id = ShopifyAPI::Utils::SessionUtils.current_session_id(session_token, nil, online_token_configured?)
        return nil unless session_id

        ShopifyApp::SessionRepository.load_session(session_id)
      end
    end
  end
end
