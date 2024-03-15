module ShopifyApp
  module AuthorizationStrategies
    module TokenExchange
      extend ActiveSupport::Concern
      include ShopifyApp::WithSessionTokenConcern

      def begin_auth
        exchange_token(
          shop: params[:shop],
          session_token: session_token,
          requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
        )

        if online_token_configured?
          exchange_token(
            shop: params[:shop],
            session_token: session_token,
            requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
          )
        end
      end

      def exchange_token(shop:, session_token:, requested_token_type:)
        return respond_to_invalid_session_token if session_token.blank?

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
            # TODO
            # perform_post_authenticate_jobs(session)
          rescue ActiveRecord::RecordNotUnique
            ShopifyApp::Logger.debug("Session not stored due to concurrent token exchange calls")
          end
        end
      end

      private

      def online_token_configured?
        !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
      end

      def respond_to_invalid_session_token
        # TODO
        console.log("ZL: respond_to_invalid_session_token")
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

