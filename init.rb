require 'shopify_api'
require 'shopify_login_protection'

if ENV['SHOPIFY_API_KEY'] && ENV['SHOPIFY_API_SECRET']
  Rails.logger.info "[Shopify App] Loading API credentials from environment"
  
  ShopifyAPI::Session.setup(:api_key => ENV['SHOPIFY_API_KEY'], :secret => ENV['SHOPIFY_API_SECRET'])
else
  config = File.join(Rails.root, "config/shopify.yml")
  
  if File.exist?(config)
    Rails.logger.info "[Shopify App] Loading API credentials from config/shopify.yml"
    
    credentials = YAML.load(File.read(config))[Rails.env]
    ShopifyAPI::Session.setup(credentials)
  else
    Rails.logger.warn '[Shopify App] Shopify App plugin installed but no config/shopify.yml found.'
  end
end

ActionController::Base.send :include, ShopifyLoginProtection
ActionController::Base.send :helper_method, :current_shop