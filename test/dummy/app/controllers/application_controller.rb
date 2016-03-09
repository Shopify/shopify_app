class ApplicationController < ActionController::Base
  include ShopifyApp::LoginProtection
end
