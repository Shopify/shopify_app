# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled
  include ShopifyApp::ShopAccessScopesVerification

  def index
    if ShopifyAPI::Context.embedded? && (!params[:embedded].present? || params[:embedded] != "1")
      embedded_app_url = safe_embedded_app_url(params[:host])
      redirect_url = embedded_app_url ? embedded_app_url + request.path : ShopifyApp.configuration.root_url
      redirect_to(redirect_url, allow_other_host: true)
    else
      @shop_origin = current_shopify_domain
      @host = params[:host]
    end
  end
end
