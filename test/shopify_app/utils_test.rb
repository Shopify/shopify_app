# frozen_string_literal: true

require_relative "../test_helper"

class UtilsTest < ActiveSupport::TestCase
  setup do
    ShopifyApp.configuration.stubs(:myshopify_domain).returns("myshopify.com")
  end

  [
    "my-shop",
    "my-shop.myshopify.com",
    "https://my-shop.myshopify.com",
    "http://my-shop.myshopify.com",
    "my-shop.shop.dev",
    "https://my-shop.shop.dev",
    "http://my-shop.shop.dev",
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
    "javascript:alert(1)",
  ].each do |bad_url|
    test "sanitize_shop_domain for a non-myshopify URL (#{bad_url})" do
      assert_nil ShopifyApp::Utils.sanitize_shop_domain(bad_url)
    end
  end

  test "#unified_admin_path returns the path to shop" do
    expected = "https://admin.shopify.com/store/my-shop"
    assert_equal expected, ShopifyApp::Utils.unified_admin_path("my-shop")
  end

  test "#unified_admin_path returns the path to shop with spin env" do
    ENV["SPIN_FQDN"] = "my.spin.dev"
    expected = "https://admin.web.my.spin.dev/store/my-shop"
    assert_equal expected, ShopifyApp::Utils.unified_admin_path("my-shop")
    ENV["SPIN_FQDN"] = nil
  end

  test "sanitize_shop_domain accepts both local conventions through DevServer" do
    core = mock("Core")
    with_dev_server(core) do
      ["shop1.my.shop.dev", "shop1.my.shop.devns.shop"].each do |host|
        core.expects(:shop_domain?).with(host).returns(true)
        assert_equal(host, ShopifyApp::Utils.sanitize_shop_domain("https://#{host}/"))
      end
    end
  end

  test "sanitize_shop_domain supports older DevServer without shop helpers" do
    with_dev_server(mock("Older Core")) do
      ["shop1.my.shop.dev", "shop1.my.shop.devns.shop"].each do |host|
        assert_equal(host, ShopifyApp::Utils.sanitize_shop_domain(host))
      end
      ["devns.shop", "my.shop.devns.shop", "app.shop.devns.shop", "shop1.my.shop.devns.shop.example.com"].each do |host|
        assert_nil(ShopifyApp::Utils.sanitize_shop_domain(host))
      end
    end
  end

  test "sanitize_shop_domain respects the shared helper rejecting a host" do
    core = mock("Core")
    core.expects(:shop_domain?).with("shop1.my.shop.devns.shop").returns(false)
    with_dev_server(core) do
      assert_nil(ShopifyApp::Utils.sanitize_shop_domain("shop1.my.shop.devns.shop"))
    end
  end

  test "sanitize_shop_domain supports DevServer without a core accessor" do
    with_dev_server(nil, core_method: false) do
      ["shop1.my.shop.dev", "shop1.my.shop.devns.shop", "shop1.myshopify.com"].each do |host|
        assert_equal(host, ShopifyApp::Utils.sanitize_shop_domain(host))
      end
      assert_nil(ShopifyApp::Utils.sanitize_shop_domain("shop1.my.shop.devns.shop.example.com"))
    end
  end

  test "sanitize_shop_domain does not trust devns shops outside dev" do
    with_dev_server(mock("Core"), enabled: false) do
      assert_nil(ShopifyApp::Utils.sanitize_shop_domain("shop1.my.shop.devns.shop"))
    end
  end

  test "sanitize_shop_domain does not trust devns shops without DevServer" do
    assert_nil(ShopifyApp::Utils.sanitize_shop_domain("shop1.my.shop.devns.shop"))
  end

  private

  def with_dev_server(core, enabled: true, core_method: true)
    previous_dev_server = Object.const_get(:DevServer) if Object.const_defined?(:DevServer)
    previous_using_dev = ENV["USING_DEV"]
    Object.send(:remove_const, :DevServer) if previous_dev_server
    dev_server = mock("DevServer")
    dev_server.stubs(:core).returns(core) if core_method
    Object.const_set(:DevServer, dev_server)
    enabled ? ENV["USING_DEV"] = "1" : ENV.delete("USING_DEV")
    yield
  ensure
    Object.send(:remove_const, :DevServer)
    Object.const_set(:DevServer, previous_dev_server) if previous_dev_server
    previous_using_dev ? ENV["USING_DEV"] = previous_using_dev : ENV.delete("USING_DEV")
  end
end
