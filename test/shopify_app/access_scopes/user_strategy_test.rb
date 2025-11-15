# frozen_string_literal: true

require_relative "../../test_helper"

module ShopifyApp
  module AccessScopes
    class UserStrategyTest < Minitest::Test
      attr_reader :user_id
      attr_reader :shopify_user_id
      attr_reader :shopify_domain

      def setup
        @user_id = 1
        @shopify_user_id = 2
        @shopify_domain = "test-shop.myshopify.com"
      end

      def test_scopes_match_for_db_generated_user_id
        ShopifyApp.configuration.user_access_scopes = "read_products"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_user_session).with(user_id)
          .returns(mock_user_session("read_products"))

        refute ShopifyApp::AccessScopes::UserStrategy.update_access_scopes?(user_id: user_id)
      end

      def test_scopes_mismatch_for_db_generated_user_id
        ShopifyApp.configuration.user_access_scopes = "write_products"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_user_session).with(user_id)
          .returns(mock_user_session("read_products"))

        assert ShopifyApp::AccessScopes::UserStrategy.update_access_scopes?(user_id: user_id)
      end

      def test_scopes_match_for_shopify_user_id
        ShopifyApp.configuration.user_access_scopes = "write_orders, read_products"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_user_session_by_shopify_user_id)
          .with(shopify_user_id)
          .returns(mock_user_session("write_orders, read_products"))

        refute ShopifyApp::AccessScopes::UserStrategy.update_access_scopes?(shopify_user_id: shopify_user_id)
      end

      def test_scopes_mismatch_for_shopify_user_id
        ShopifyApp.configuration.user_access_scopes = "write_orders, read_customers"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_user_session_by_shopify_user_id)
          .with(shopify_user_id)
          .returns(mock_user_session("write_orders, read_products"))

        assert ShopifyApp::AccessScopes::UserStrategy.update_access_scopes?(shopify_user_id: shopify_user_id)
      end

      def test_assert_invalid_input_error_when_no_parameters_passed_in
        assert_raises ::ShopifyApp::InvalidInput do
          assert ShopifyApp::AccessScopes::UserStrategy.update_access_scopes?
        end
      end

      private

      def mock_user_session(scopes)
        ShopifyAPI::Auth::Session.new(
          shop: shopify_domain,
          access_token: "access_token",
          scope: scopes,
        )
      end
    end
  end
end
