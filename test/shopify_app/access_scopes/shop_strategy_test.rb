# frozen_string_literal: true
require "test_helper"

module ShopifyApp
  module AccessScopes
    class ShopStrategyTest < Minitest::Test
      attr_reader :shopify_domain

      def setup
        @shopify_domain = "shop.myshopify.com"
      end

      def test_scopes_dont_mismatch_if_configuration_and_stored_scope_are_same
        ShopifyApp.configuration.shop_access_scopes = "read_products"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_shop_session_by_shopify_domain)
          .with(shopify_domain)
          .returns(mock_shop_session("read_products"))

        refute ShopifyApp::AccessScopes::ShopStrategy.update_access_scopes?(shopify_domain)
      end

      def test_scopes_mismatch_if_configuration_and_stored_scopes_are_not_the_same
        ShopifyApp.configuration.shop_access_scopes = "write_products"
        ShopifyApp::SessionRepository
          .stubs(:retrieve_shop_session_by_shopify_domain)
          .with(shopify_domain)
          .returns(mock_shop_session("read_products"))

        assert ShopifyApp::AccessScopes::ShopStrategy.update_access_scopes?(shopify_domain)
      end

      private

      def mock_shop_session(scopes)
        ShopifyAPI::Session.new(
          domain: shopify_domain,
          token: "access_token",
          api_version: "2021-02",
          access_scopes: scopes
        )
      end
    end
  end
end
