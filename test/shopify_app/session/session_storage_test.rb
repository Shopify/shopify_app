# frozen_string_literal: true

require "test_helper"

module Shopify
  class SessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890abcdef"

    test 'proc params of #with_shopify_session should be ShopifyAPI::Auth::Session' do
      shop_mock = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
      )
      shop_mock.class_eval do
        include ActiveModel::Validations
        include ShopifyApp::SessionStorage
      end

      shop_mock.with_shopify_session do |session|
        assert_instance_of ShopifyAPI::Auth::Session, session
        assert_equal TEST_SHOPIFY_DOMAIN, session.shop
        assert_equal TEST_SHOPIFY_TOKEN, session.access_token
      end
    end
  end
end
