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
        if embedded_param?
          redirect_for_embedded
        else
          redirect_to(shop_login)
        end
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

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], host: params[:host], return_to: request.fullpath)
    end
  end
end
