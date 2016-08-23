module ShopifyApp
  class SessionsController < ApplicationController
    include ShopifyApp::SessionsConcern
    layout false
  end
end
