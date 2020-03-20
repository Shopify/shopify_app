# typed: strict
module ShopifyAPI
  class Base < ActiveResource::Base
    self.headers['User-Agent'] << " | ShopifyApp/#{ShopifyApp::VERSION}"
  end
end
