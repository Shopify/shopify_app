# frozen_string_literal: true
require 'test_helper'

class UserStrategyTest < Minitest::Test
  attr_reader :user_id
  attr_reader :shopify_user_id

  def setup
    @user_id = 1
    @shopify_user_id = 2
  end

  def test_scopes_match_for_db_generated_user_id
    ShopifyApp::SessionRepository.stubs(:retrieve_user_access_scopes).with(user_id).returns("read_products")
    ShopifyApp.configuration.user_access_scopes = "read_products"

    refute ShopifyApp::AccessScopes::UserStrategy.scopes_mismatch_by_user_id?(user_id)
  end

  def test_scopes_mismatch_for_db_generated_user_id
    ShopifyApp::SessionRepository.stubs(:retrieve_user_access_scopes).with(user_id).returns("read_products")
    ShopifyApp.configuration.user_access_scopes = "write_products"

    assert ShopifyApp::AccessScopes::UserStrategy.scopes_mismatch_by_user_id?(user_id)
  end

  def test_scopes_match_for_shopify_user_id
    ShopifyApp::SessionRepository
      .stubs(:retrieve_user_access_scopes_by_shopify_user_id)
      .with(shopify_user_id)
      .returns("read_products, write_orders")
    ShopifyApp.configuration.user_access_scopes = "write_orders, read_products"

    refute ShopifyApp::AccessScopes::UserStrategy.scopes_mismatch_by_shopify_user_id?(shopify_user_id)
  end

  def test_scopes_mismatch_for_shopify_user_id
    ShopifyApp::SessionRepository
      .stubs(:retrieve_user_access_scopes_by_shopify_user_id)
      .with(shopify_user_id)
      .returns("read_products, write_orders")
    ShopifyApp.configuration.user_access_scopes = "write_orders, read_customers"

    assert ShopifyApp::AccessScopes::UserStrategy.scopes_mismatch_by_shopify_user_id?(shopify_user_id)
  end
end
