# frozen_string_literal: true

module ShopifyApp
  module ShopAccessScopesVerification
    extend ActiveSupport::Concern

    included do
      before_action :login_on_scope_changes
    end

    protected

    def login_on_scope_changes
      redirect_to(shop_login) if scopes_mismatch?
    end

    private

    def scopes_mismatch?
      ShopifyApp.configuration.shop_access_scopes_strategy.update_access_scopes?(current_shopify_domain)
    end

    def current_shopify_domain
      return if params[:shop].blank?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], return_to: request.fullpath)
    end
  end
end
