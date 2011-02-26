require 'rails'

class ShopifyApp::Railtie < ::Rails::Railtie

  config.before_configuration do
    config.shopify = ShopifyApp.configuration
  end
  
  initializer "shopify_app.action_controller_integration" do
    ActionController::Base.send :include, ShopifyApp::LoginProtection
    ActionController::Base.send :helper_method, :current_shop
  end
  
  initializer "shopify_app.setup_session" do
    ShopifyApp.setup_session
  end
end
