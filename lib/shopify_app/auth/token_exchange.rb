# frozen_string_literal: true

module ShopifyApp
  module Auth
    class TokenExchange
      attr_reader :id_token

      def self.perform(id_token)
        new(id_token).perform
      end

      def initialize(id_token)
        @id_token = id_token
      end

      def perform
        domain = ShopifyApp::JWT.new(id_token).shopify_domain

        Logger.info("Performing Token Exchange for [#{domain}] - (Offline)")
        session = exchange_token(
          shop: domain,
          id_token: id_token,
          requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
        )

        if online_token_configured?
          Logger.info("Performing Token Exchange for [#{domain}] - (Online)")
          session = exchange_token(
            shop: domain,
            id_token: id_token,
            requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
          )
        end

        ShopifyApp.configuration.post_authenticate_tasks.perform(session)

        session
      end

      private

      def exchange_token(shop:, id_token:, requested_token_type:)
        session = ShopifyAPI::Auth::TokenExchange.exchange_token(
          shop: shop,
          session_token: id_token,
          requested_token_type: requested_token_type,
        )

        SessionRepository.store_session(session)

        session
      rescue ShopifyAPI::Errors::InvalidJwtTokenError
        Logger.error("Invalid id token '#{id_token}' during token exchange")
        raise
      rescue ShopifyAPI::Errors::HttpResponseError => error
        Logger.error(
          "A #{error.code} error (#{error.class}) occurred during the token exchange. Response: #{error.response.body}",
        )
        raise
      rescue ActiveRecord::RecordNotUnique
        Logger.debug("Session not stored due to concurrent token exchange calls")
        session
      rescue => error
        Logger.error("An error occurred during the token exchange: [#{error.class}] #{error.message}")
        raise
      end

      def online_token_configured?
        ShopifyApp.configuration.online_token_configured?
      end
    end
  end
end
