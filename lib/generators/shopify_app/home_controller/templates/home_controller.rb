# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopHost
  include ShopifyApp::ShopAccessScopesVerification

  def index
    @products = ShopifyAPI::Product.all(limit: 10)
    @webhooks = ShopifyAPI::Webhook.all
  end
end
