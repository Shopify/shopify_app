module ShopifyApp
  module AuthorizationStrategies
    module TokenExchange
      extend ActiveSupport::Concern
      include ShopifyApp::WithSessionContext

      def authenticate_session
        if current_shopify_session.blank? || session_expired?
          return begin_auth
        end

        true
      end

      def begin_auth
        # TODO: Right now JWT Middleware only updates env['jwt.shopify_domain'] from request headers tokens, which won't work for new installs
        # We need to update the middleware to also update the env['jwt.shopify_domain'] from the query params
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

        ShopifyApp::Auth::PostAuthenticateTasks.perform(session) if session

        session
      end

      private

      def session_expired?
        ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
      end

      def exchange_token(shop:, session_token:, requested_token_type:)
        if session_token.blank?
          respond_to_invalid_session_token 
          return
        end

        begin
          session = ShopifyAPI::Auth::TokenExchange.exchange_token(
            shop: shop,
            session_token: session_token,
            requested_token_type: requested_token_type,
          )
        rescue ShopifyAPI::Errors::InvalidJwtTokenError
          respond_to_invalid_session_token
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

      def online_token_configured?
        !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
      end

      def respond_to_invalid_session_token
        # TODO
        # if request.xhr?
          # response.set_header("X-Shopify-Retry-Invalid-Session-Request", 1)
          # unauthorized_response = {
            # message: :unauthorized,
          # }
          # render(json: { errors: [unauthorized_response] }, status: :unauthorized)
        # else
          # patch_session_token_url = "#{ShopifyAPI::Context.host}#{Rails.application.config.patch_session_token_url}"
          # patch_session_token_params = request.query_parameters.except(:id_token)

          # bounce_url = "#{ShopifyAPI::Context.host}#{request.path}?#{patch_session_token_params.to_query}"

          # # App Bridge will trigger a fetch to the URL in shopify-reload, with a new session token in headers
          # patch_session_token_params["shopify-reload"] = bounce_url

          # redirect_to("#{patch_session_token_url}?#{patch_session_token_params.to_query}", allow_other_host: true)
        # end
      end
    end
  end
end

