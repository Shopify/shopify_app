# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopAccessScopesVerification

  before_action :set_host

  def index
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @webhooks = ShopifyAPI::Webhook.find(:all)
  end

  private

  def set_host
    @host = params[:host]
  end
end
