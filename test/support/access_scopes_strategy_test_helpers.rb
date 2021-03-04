# frozen_string_literal: true
module AccessScopesStrategyHelpers
  def mock_shop_scopes_mismatch_strategy
    ShopifyApp::AccessScopes::ShopStrategy.stubs(:update_access_scopes?).returns(true)
  end

  def mock_shop_scopes_match_strategy
    ShopifyApp::AccessScopes::ShopStrategy.stubs(:update_access_scopes?).returns(false)
  end

  def mock_user_scopes_match_strategy
    ShopifyApp::AccessScopes::UserStrategy.stubs(:update_access_scopes?).returns(false)
  end

  def mock_user_scopes_mismatch_strategy
    ShopifyApp::AccessScopes::UserStrategy.stubs(:update_access_scopes?).returns(true)
  end
end
