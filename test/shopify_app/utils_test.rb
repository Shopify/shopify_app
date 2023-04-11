# frozen_string_literal: true

require "test_helper"

class UtilsTest < ActiveSupport::TestCase
  setup do
    ShopifyApp.configuration.stubs(:myshopify_domain).returns("myshopify.com")
  end

  [
    "my-shop",
    "my-shop.myshopify.com",
    "https://my-shop.myshopify.com",
    "http://my-shop.myshopify.com",
  ].each do |good_url|
    test "sanitize_shop_domain for (#{good_url})" do
      assert ShopifyApp::Utils.sanitize_shop_domain(good_url)
    end
  end

  [
    "my-shop",
    "my-shop.myshopify.io",
    "http-shop-from-qa-hell.myshopify.com",
    "https://my-shop.myshopify.io",
    "http://my-shop.myshopify.io",
  ].each do |good_url|
    test "sanitize_shop_domain URL (#{good_url}) with custom myshopify_domain" do
      ShopifyApp.configuration.myshopify_domain = "myshopify.io"
      assert ShopifyApp::Utils.sanitize_shop_domain(good_url)
    end
  end

  test "sanitize_shop_domain URL shopify spin.dev custom myshopify_domain" do
    myshop_domain = "http://shopify.foobar-part-onboard-0d6x.asdf-rygus.us.spin.dev"
    ShopifyApp.configuration.stubs(:myshopify_domain).returns(myshop_domain)
    unified_admin_url = myshop_domain + "/store/shop1/apps/cool_app_hansel"

    assert ShopifyApp::Utils.sanitize_shop_domain(unified_admin_url)
  end

  test "sanitize_shop_domain for url with uppercase characters" do
    assert ShopifyApp::Utils.sanitize_shop_domain("MY-shop.myshopify.com")
  end

  test "unified admin is still trusted as a sanitzed domain" do
    ShopifyApp.configuration.stubs(:myshpoify_domain).returns("totally.cool.domain.com")
    assert ShopifyApp::Utils.sanitize_shop_domain("admin.shopify.com/some_shoppe_over_the_rainbow")
    assert ShopifyApp::Utils.sanitize_shop_domain("some-shoppe-over-the-rainbow.myshopify.com")
    assert ShopifyApp::Utils.sanitize_shop_domain("some-shoppe-over-the-rainbow.myshopify.io")
  end

  test "convert unified admin to old domain" do
    trailing_forward_slash_url = "https://admin.shopify.com/store/store-name/"
    unified_admin_url = "https://admin.shopify.com/store/store-name"

    expected = "store-name.myshopify.com"

    assert_equal expected, ShopifyApp::Utils.sanitize_shop_domain(trailing_forward_slash_url)
    assert_equal expected, ShopifyApp::Utils.sanitize_shop_domain(unified_admin_url)
  end

  [
    "myshop.com",
    "myshopify.com",
    "shopify.com",
    "two words",
    "store.myshopify.com.evil.com",
    "/foo/bar",
    "foo.myshopify.io.evil.ru",
  ].each do |bad_url|
    test "sanitize_shop_domain for a non-myshopify URL (#{bad_url})" do
      assert_nil ShopifyApp::Utils.sanitize_shop_domain(bad_url)
    end
  end
end
