# frozen_string_literal: true

module ShopifyApp
  module ScopeUtilities
    def login_on_scope_changes(current_merchant_scopes, configuration_scopes)
      redirect_to(shop_login) if scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
    end

    def scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
      return true if current_merchant_scopes.nil?
      ShopifyAPI::ApiAccess.new(current_merchant_scopes) != ShopifyAPI::ApiAccess.new(configuration_scopes)
    end

    private

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], return_to: request.fullpath)
    end
  end
end
