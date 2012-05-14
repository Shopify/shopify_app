require 'shopify_api'
require 'omniauth-shopify-oauth2'

module ShopifyApp

  def self.configuration
    @configuration ||= ShopifyApp::Configuration.new
  end
  
  def self.setup_session
    ShopifyAPI::Session.setup(:api_key => ShopifyApp.configuration.api_key, :secret => ShopifyApp.configuration.secret)
  end
end

require 'shopify_app/login_protection'
require 'shopify_app/configuration'
require 'shopify_app/railtie'
require 'shopify_app/version'
