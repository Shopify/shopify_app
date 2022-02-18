# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopAccessScopesVerification

  before_action :set_host

  def index
    @products = ShopifyAPI::Product.all(limit: 10, session: current_shopify_session)
    @webhooks = ShopifyAPI::Webhook.all(session: current_shopify_session)
  end

  private

  def set_host
    @host = params[:host]
  end
end
