# frozen_string_literal: true

module ShopifyApp
  module Auth
    class TokenExchange
      attr_reader :session_token

      def self.perform(session_token)
        new(session_token).perform
      end

      def initialize(session_token)
        @session_token = session_token
      end

      def perform
        domain = ShopifyApp::JWT.new(session_token).shopify_domain

        Logger.info("Performing Token Exchange for [#{domain}] - (Offline)")
        session = exchange_token(
          shop: domain, # TODO: use jwt_shopify_domain ?
          session_token: session_token,
          requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
        )

        if session && online_token_configured?
          Logger.info("Performing Token Exchange for [#{domain}] - (Online)")
          session = exchange_token(
            shop: domain, # TODO: use jwt_shopify_domain ?
            session_token: session_token,
            requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
          )
        end

        ShopifyApp.configuration.post_authenticate_tasks.perform(session)
      end

      private

      def exchange_token(shop:, session_token:, requested_token_type:)
        begin
          session = ShopifyAPI::Auth::TokenExchange.exchange_token(
            shop: shop,
            session_token: session_token,
            requested_token_type: requested_token_type,
          )
        rescue ShopifyAPI::Errors::InvalidJwtTokenError
          Logger.error("Invalid session token '#{session_token}' during token exchange")
          raise
        rescue ShopifyAPI::Errors::HttpResponseError => error
          Logger.error(
            "A #{error.code} error (#{error.class}) occurred during the token exchange. Response: #{error.response.body}",
          )
          raise
        rescue => error
          Logger.error("An error occurred during the token exchange: [#{error.class}] #{error.message}")
          raise
        end

        begin
          SessionRepository.store_session(session)
        rescue ActiveRecord::RecordNotUnique
          Logger.debug("Session not stored due to concurrent token exchange calls")
        end

        session
      end

      def online_token_configured?
        ShopifyApp.configuration.online_token_configured?
      end
    end
  end
end
