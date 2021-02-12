module ShopifyApp
  class ScopeUtilities
    def self.access_scopes_mismatch?(current_access_scopes, configuration_access_scopes)
      return true if current_access_scopes.nil?
      ShopifyAPI::ApiAccess.new(current_access_scopes) != ShopifyAPI::ApiAccess.new(configuration_access_scopes)
    end
  end
end
