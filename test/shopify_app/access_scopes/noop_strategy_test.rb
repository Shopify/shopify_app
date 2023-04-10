# frozen_string_literal: true

require "test_helper"

module ShopifyApp
  module AccessScopes
    class NoopStrategyTest < Minitest::Test
      attr_reader :shopify_domain
      attr_reader :user_id
      attr_reader :shopify_user_id

      def setup
        @shopify_domain = "shop.myshopify.com"
        @user_id = 1
        @shopify_user_id = 2
      end

      def test_scope_update_is_never_required_for_shopify_domain
        refute ShopifyApp::AccessScopes::NoopStrategy.update_access_scopes?(shopify_domain)
      end

      def test_scope_update_is_never_required_for_user_id
        refute ShopifyApp::AccessScopes::NoopStrategy.update_access_scopes?(user_id: user_id)
      end

      def test_scope_update_is_never_required_for_shopify_user_id
        refute ShopifyApp::AccessScopes::NoopStrategy.update_access_scopes?(shopify_user_id: shopify_user_id)
      end
    end
  end
end
