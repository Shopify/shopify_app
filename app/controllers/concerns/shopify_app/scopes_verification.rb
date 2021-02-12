# frozen_string_literal: true

module ShopifyApp
  module ScopesVerification
    extend ActiveSupport::Concern

    included do
      before_action :login_on_scope_changes
    end

    protected

    def login_on_scope_changes
      if scopes_configuration_mismatch?(current_merchant_access_scopes, configuration_access_scopes)
        redirect_to(shop_login)
      end
    end

    def current_merchant_access_scopes
      ShopifyApp::SessionRepository.retrieve_shop_access_scopes(current_shopify_domain)
    end

    def configuration_access_scopes
      ShopifyApp.configuration.shop_access_scopes
    end

    def scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
      return true if current_merchant_scopes.nil?
      ShopifyAPI::ApiAccess.new(current_merchant_scopes) != ShopifyAPI::ApiAccess.new(configuration_scopes)
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
