# frozen_string_literal: true

module ShopifyApp
  module ScopeUtilities
    def scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
      return true if current_merchant_scopes.nil?
      ShopifyAPI::ApiAccess.new(current_merchant_scopes) != ShopifyAPI::ApiAccess.new(configuration_scopes)
    end
  end
end
