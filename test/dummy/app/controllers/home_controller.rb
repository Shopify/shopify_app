# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::RequireKnownShop

  def index
    "index"
  end
end
