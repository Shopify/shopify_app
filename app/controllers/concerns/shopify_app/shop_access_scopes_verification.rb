# frozen_string_literal: true

module ShopifyApp
  module ShopAccessScopesVerification
    extend ActiveSupport::Concern
    include ShopifyApp::RedirectForEmbedded

    included do
      before_action :login_on_scope_changes
    end

    protected

    def login_on_scope_changes
      if scopes_mismatch?
        ShopifyApp::Logger.debug("redirecting due to scope mismatch, target: #{reauthorized_shop_login_url}")
        fullpage_redirect_to(reauthorized_shop_login_url)
      end
    end

    private

    def scopes_mismatch?
      ShopifyApp.configuration.shop_access_scopes_strategy.update_access_scopes?(current_shopify_domain)
    end

    def current_shopify_domain
      return if params[:shop].blank?

      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def reauthorized_shop_login_url
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], host: params[:host], return_to: request.fullpath,
        reauthorize: true)
    end

    def fullpage_redirect_to(url)
      render("shopify_app/shared/redirect", layout: false,
        locals: { url: reauthorized_shop_login_url, current_shopify_domain: current_shopify_domain })
    end
  end
end
