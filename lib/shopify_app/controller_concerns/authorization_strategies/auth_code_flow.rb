module ShopifyApp
  module AuthorizationStrategies
    module AuthCodeFlow
      include ShopifyApp::RedirectForEmbedded
      extend ActiveSupport::Concern

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
    end
  end
end

