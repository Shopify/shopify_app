# frozen_string_literal: true

module ShopifyApp
  # Helper methods for App Bridge Utilities
  module AccessToken
    ACCESS_TOKEN_REQUIRED_HEADER = 'X-Shopify-API-Request-Failure-Unauthorized'

    def signal_access_token_required
      response.set_header(ACCESS_TOKEN_REQUIRED_HEADER, true)
    end

    def user_session_expected?
      !ShopifyApp.configuration.user_session_repository.blank? && ShopifyApp::SessionRepository.user_storage.present?
    end
  end
end
