# frozen_string_literal: true

class HomeController < AuthenticatedController
  include ShopifyApp::ShopAccessScopesVerification

  before_action :set_host

  def index
    @products = ShopifyAPI::Product.all(session: ShopifyAPI::Context.active_session, limit: 10)
    @webhooks = ShopifyAPI::Webhook.all(session: ShopifyAPI::Context.active_session)
  end

  private

  def set_host
    @host = params[:host]
  end
end
