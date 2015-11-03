class Shop < ActiveRecord::Base
  include ShopifyApp::Shop
  include ShopifyApp::SessionStorage
end
