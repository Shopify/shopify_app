# frozen_string_literal: true

require "test_helper"

class UtilsTest < ActiveSupport::TestCase
  setup do
    ShopifyApp.configuration = nil
  end

  ["my-shop", "my-shop.myshopify.com",
   "https://my-shop.myshopify.com",
   "http://my-shop.myshopify.com",].each do |good_url|
    test "sanitize_shop_domain for (#{good_url})" do
      assert ShopifyApp::Utils.sanitize_shop_domain(good_url)
    end
  end

  ["my-shop", "my-shop.myshopify.io", "https://my-shop.myshopify.io", "http://my-shop.myshopify.io"].each do |good_url|
    test "sanitize_shop_domain URL (#{good_url}) with custom myshopify_domain" do
      ShopifyApp.configuration.myshopify_domain = "myshopify.io"
      assert ShopifyApp::Utils.sanitize_shop_domain(good_url)
    end
  end

  test "sanitize_shop_domain for url with uppercase characters" do
    assert ShopifyApp::Utils.sanitize_shop_domain("MY-shop.myshopify.com")
  end

  ["myshop.com", "myshopify.com", "shopify.com", "two words", "store.myshopify.com.evil.com",
   "/foo/bar", "foo.myshopify.io.evil.ru", "%0a123.myshopify.io",
   "foo.bar.myshopify.io",].each do |bad_url|
    test "sanitize_shop_domain for a non-myshopify URL (#{bad_url})" do
      assert_nil ShopifyApp::Utils.sanitize_shop_domain(bad_url)
    end
  end

  test "shop_login_url with a reauthorize param" do
    assert_equal "/login?shop=myshop&host=myhost&return_to=&reauthorize=1",
      ShopifyApp::Utils.shop_login_url(shop: "myshop", host: "myhost", return_to: "", reauthorize: true)
  end

  test "shop_login_url without a reauthorize param" do
    assert_equal "/login?shop=myshop&host=myhost&return_to=",
      ShopifyApp::Utils.shop_login_url(shop: "myshop", host: "myhost", return_to: "")
  end
end
