# frozen_string_literal: true
module ShopifyAPI
  class Base < ActiveResource::Base
    headers['User-Agent'] << " | ShopifyApp/#{ShopifyApp::VERSION}"
  end
end
