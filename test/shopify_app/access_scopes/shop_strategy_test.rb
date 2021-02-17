# frozen_string_literal: true
require 'test_helper'

module ShopifyApp
  module AccessScopes
    class ShopStrategyTest < Minitest::Test
      attr_reader :shopify_domain

      def setup
        @shopify_domain = "shop.myshopify.com"
      end

      def test_scopes_dont_mismatch_if_configuration_and_stored_scope_are_same
        ShopifyApp::SessionRepository.stubs(:retrieve_shop_access_scopes).with(shopify_domain).returns("read_products")
        ShopifyApp.configuration.shop_access_scopes = "read_products"

        refute ShopifyApp::AccessScopes::ShopStrategy.scopes_mismatch?(shopify_domain)
      end

      def test_scopes_mismatch_if_configuration_and_stored_scopes_are_not_the_same
        ShopifyApp::SessionRepository.stubs(:retrieve_shop_access_scopes).with(shopify_domain).returns("write_products")
        ShopifyApp.configuration.shop_access_scopes = "read_products"

        assert ShopifyApp::AccessScopes::ShopStrategy.scopes_mismatch?(shopify_domain)
      end
    end
  end
end
