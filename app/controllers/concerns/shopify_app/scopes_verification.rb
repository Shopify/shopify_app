# frozen_string_literal: true

module ShopifyApp
  module ScopesVerification
    extend ActiveSupport::Concern
    include ScopeUtilities

    included do
      before_action do
        login_on_scope_changes(current_merchant_scopes, configuration_scopes)
      end
    end

    protected

    def login_on_scope_changes(current_merchant_scopes, configuration_scopes)
      redirect_to(shop_login) if scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
    end

    def current_merchant_scopes
      ShopifyApp::SessionRepository.retrieve_shop_scopes(current_shopify_domain)
    end

    def configuration_scopes
      ShopifyApp.configuration.scope
    end

    private

    def current_shopify_domain
      return if params[:shop].blank?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], return_to: request.fullpath)
    end
  end
end
