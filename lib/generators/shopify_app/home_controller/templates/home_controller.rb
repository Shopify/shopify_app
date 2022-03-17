# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopAccessScopesVerification

  before_action :set_host

  def index
    @products = ShopifyAPI::Product.all(limit: 10)
    @webhooks = ShopifyAPI::Webhook.all
  end

  private

  def set_host
    @host = params[:host]
  end
end
