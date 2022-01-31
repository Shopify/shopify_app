# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::ShopHost
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::RequireKnownShop
  include ShopifyApp::ShopAccessScopesVerification

  def index
    @shop_origin = current_shopify_domain
  end
end
