# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopHost
  include ShopifyApp::ShopAccessScopesVerification

  def index
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @webhooks = ShopifyAPI::Webhook.find(:all)
  end
end
