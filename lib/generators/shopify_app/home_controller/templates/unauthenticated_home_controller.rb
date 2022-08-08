# frozen_string_literal: true

class HomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::RequireKnownShop
  include ShopifyApp::ShopAccessScopesVerification

  def index
    if ShopifyAPI::Context.embedded? && !params[:embedded].present? || params[:embedded] != "1"
      # TODO: replace this param with ShopifyAPI::Auth.embedded_app_url or whatever the new
      # method name will be, once https://github.com/Shopify/shopify-api-ruby/pull/1002 is merged
      redirect_to(embedded_app_url(params[:host]) + request.path, allow_other_host: true)
    else
      @shop_origin = current_shopify_domain
      @host = params[:host]
    end
  end

  private

  # TODO: remove this once https://github.com/Shopify/shopify-api-ruby/pull/1002
  # is merged and released
  def embedded_app_url(host)
    decoded_host = Base64.decode64(host)
    "https://#{decoded_host}/apps/#{ShopifyAPI::Context.api_key}"
  end
end
