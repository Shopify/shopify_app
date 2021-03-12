# frozen_string_literal: true
require 'test_helper'

module ShopifyApp
  class OmniAuthConfigurationTest < Minitest::Test
    attr_reader :strategy, :request

    def setup
      mock_shop_scopes_match_strategy
      ShopifyApp.configuration.old_secret = 'old_secret'
      ShopifyApp.configuration.user_access_scopes = 'read_products, read_orders'
      ShopifyApp.configuration.shop_access_scopes = 'write_products, write_themes'
      ShopifyApp.configuration.reauth_on_access_scope_changes = true
      @strategy = mock_strategy
      @request = mock_request
    end

    def test_configuration_builds_strategy_options_for_online_tokens
      configuration = OmniAuthConfiguration.new(strategy, request)

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.user_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      assert strategy.options[:per_user_permissions]
    end

    def test_configuration_builds_strategy_options_for_offline_tokens
      strategy.session[:user_tokens] = false
      configuration = OmniAuthConfiguration.new(strategy, request)

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.shop_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      refute strategy.options[:per_user_permissions]
    end

    def test_configuration_configures_client_options_site_to_specified_value
      configuration = OmniAuthConfiguration.new(strategy, request)
      configuration.client_options_site = 'something.entirely.made.up'

      configuration.build_options

      assert_equal "something.entirely.made.up", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.user_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      assert strategy.options[:per_user_permissions]
    end

    def test_configuration_configures_scope_to_specified_value
      configuration = OmniAuthConfiguration.new(strategy, request)
      configuration.scopes = 'write_customers'

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal 'write_customers', strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      assert strategy.options[:per_user_permissions]
    end

    def test_configuration_configures_per_user_permissions_to_specified_value
      configuration = OmniAuthConfiguration.new(strategy, request)
      configuration.per_user_permissions = false

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.shop_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      refute strategy.options[:per_user_permissions]
    end

    def test_configuration_builds_strategy_options_for_offline_tokens_if_shop_requires_scopes
      mock_mismatch_shop_scopes_strategy
      configuration = OmniAuthConfiguration.new(strategy, request)

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.shop_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      refute strategy.options[:per_user_permissions]
    end

    def test_configuration_ignores_shop_scope_mismatch_if_per_user_permissions_over_written
      mock_mismatch_shop_scopes_strategy
      configuration = OmniAuthConfiguration.new(strategy, request)
      configuration.per_user_permissions = true

      configuration.build_options

      assert_equal "https://shop.myshopify.com", strategy.options[:client_options][:site]
      assert_equal ShopifyApp.configuration.user_access_scopes, strategy.options[:scope]
      assert_equal ShopifyApp.configuration.old_secret, strategy.options[:old_client_secret]
      assert strategy.options[:per_user_permissions]
    end

    private

    def mock_shop_scopes_match_strategy
      ShopifyApp::AccessScopes::ShopStrategy.stubs(:update_access_scopes?).returns(false)
    end

    def mock_mismatch_shop_scopes_strategy
      ShopifyApp::AccessScopes::ShopStrategy.stubs(:update_access_scopes?).returns(true)
    end

    def mock_strategy
      OpenStruct.new(
        session: {
          user_tokens: true,
          'shopify.omniauth_params' => {
            shop: 'shop.myshopify.com',
          }.with_indifferent_access,
        }.with_indifferent_access,
        options: {
          client_options: {},
        }.with_indifferent_access
      )
    end

    def mock_request
      OpenStruct.new(
        params: {
          shop: 'shop.myshopify.com',
        }.with_indifferent_access
      )
    end
  end
end
