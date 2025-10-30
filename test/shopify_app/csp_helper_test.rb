# frozen_string_literal: true

require "test_helper"

class CspHelperTest < ActiveSupport::TestCase
  setup do
    @policy = ActionDispatch::ContentSecurityPolicy.new
  end

  test "adds App Bridge script source to empty policy" do
    ShopifyApp.add_csp_directives(@policy)

    script_src = @policy.directives["script-src"]
    assert_includes script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end

  test "adds App Bridge script source to existing policy with script-src" do
    @policy.script_src(:self, :https)

    ShopifyApp.add_csp_directives(@policy)

    script_src = @policy.directives["script-src"]
    assert_includes script_src, "'self'"
    assert_includes script_src, "https:"
    assert_includes script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end

  test "does not duplicate App Bridge URL if already present" do
    @policy.script_src(:self, "https://cdn.shopify.com/shopifycloud/app-bridge.js")

    ShopifyApp.add_csp_directives(@policy)

    script_src = @policy.directives["script-src"]
    # Count occurrences of the URL
    count = script_src.count("https://cdn.shopify.com/shopifycloud/app-bridge.js")
    assert_equal 1, count, "App Bridge URL should only appear once"
  end

  test "preserves unsafe-inline directive" do
    @policy.script_src(:self, :unsafe_inline)

    ShopifyApp.add_csp_directives(@policy)

    script_src = @policy.directives["script-src"]
    assert_includes script_src, "'self'"
    assert_includes script_src, "'unsafe-inline'"
    assert_includes script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end

  test "works with complex script-src configuration" do
    @policy.script_src(:self, :https, "https://cdn.shopify.com/shopifycloud/my-app/", :unsafe_inline)

    ShopifyApp.add_csp_directives(@policy)

    script_src = @policy.directives["script-src"]
    assert_includes script_src, "'self'"
    assert_includes script_src, "https:"
    assert_includes script_src, "https://cdn.shopify.com/shopifycloud/my-app/"
    assert_includes script_src, "'unsafe-inline'"
    assert_includes script_src, "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end
end
