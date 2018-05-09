class HomeController < ApplicationController
  include ShopifyApp::AuthenticatedByShopify

  def index
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @webhooks = ShopifyAPI::Webhook.find(:all)
  end
end
