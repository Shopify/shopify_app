module ShopifyApp
  module AuthorizationStrategy
    extend ActiveSupport::Concern

    included do
      if ShopifyApp.configuration.use_new_embedded_auth_strategy?
        include ShopifyApp::AuthorizationStrategies::TokenExchange
      else
        include ShopifyApp::AuthorizationStrategies::AuthCodeFlow
      end
    end
  end
end

