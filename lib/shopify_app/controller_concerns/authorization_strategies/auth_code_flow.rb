module ShopifyApp
  module AuthorizationStrategies
    module AuthCodeFlow
      include ShopifyApp::RedirectForEmbedded
      extend ActiveSupport::Concern

      ACCESS_TOKEN_REQUIRED_HEADER = "X-Shopify-API-Request-Failure-Unauthorized"

      def authenticate_session
        if current_shopify_session.blank?
          signal_access_token_required
          ShopifyApp::Logger.debug("No session found, redirecting to login")
          redirect_to_login
          return false
        end

        if ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
          ShopifyApp::Logger.debug("Session expired, redirecting to login")
          clear_shopify_session
          redirect_to_login
          return false
        end

        if ShopifyApp.configuration.reauth_on_access_scope_changes &&
            !ShopifyApp.configuration.user_access_scopes_strategy.covers_scopes?(current_shopify_session)
          ShopifyApp::Logger.debug("Access scope has changed, redirecting to login")
          clear_shopify_session
          redirect_to_login
          return false
        end

        true
      end

      def begin_auth
        if embedded_param?
          redirect_for_embedded
        else
          redirect_to(shop_login)
        end
      end

      private

      def shop_login
        url = URI(ShopifyApp.configuration.login_url)

        url.query = URI.encode_www_form(
          shop: params[:shop],
          host: params[:host],
          return_to: request.fullpath,
        )

        url.to_s
      end

      def signal_access_token_required
        response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, "true")
      end
    end
  end
end

