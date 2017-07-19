class Shop < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end
