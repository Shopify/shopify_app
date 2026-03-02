# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled
  include ShopifyApp::ShopAccessScopesVerification

  def index
    if ShopifyAPI::Context.embedded? && (!params[:embedded].present? || params[:embedded] != "1")
      redirect_url = ShopifyAPI::Auth.embedded_app_url(params[:host]) + request.path
      redirect_url = ShopifyApp.configuration.root_url if deduced_phishing_attack?(redirect_url)
      redirect_to(redirect_url, allow_other_host: true)
    else
      @shop_origin = current_shopify_domain
      @host = params[:host]
    end
  end
end
