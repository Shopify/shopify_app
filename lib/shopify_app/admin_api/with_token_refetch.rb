# frozen_string_literal: true

module ShopifyApp
  module AdminAPI
    module WithTokenRefetch
      def with_token_refetch(session)
        retried = false
        yield
      rescue ShopifyAPI::Errors::HttpResponseError => error
        session_token = session.session_token
        if error.code == 401 && session_token && !retried
          retried = true
          ShopifyApp::Logger.debug("Encountered 401 error, exchanging token and retrying with new access token")
          session.attributes = ShopifyApp::Auth::TokenExchange.perform(session_token).attributes
          session.session_token = session_token
          retry
        else
          ShopifyApp::Logger.debug("Encountered error: #{error.code} - #{error.message}, re-raising")
          raise
        end
      end
    end
  end
end
