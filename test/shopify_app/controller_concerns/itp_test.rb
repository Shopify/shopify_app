# frozen_string_literal: true

require 'test_helper'

class ItpTest < ActiveSupport::TestCase
  include ShopifyApp::Itp

  test "should_set_test_cookie? returns false unless app is embedded_app" do
    ShopifyApp.configuration.embedded_app = false

    refute should_set_test_cookie?
  end

  test "should_set_test_cookie? returns false app uses jwt auth" do
    ShopifyApp.configuration.allow_jwt_authentication = true

    refute should_set_test_cookie?
  end

  test "should_set_test_cookie? returns false unless user_agent can partition cookies" do
    stubs(:user_agent_can_partition_cookies).returns(false)

    refute should_set_test_cookie?
  end

  test "should_set_test_cookie? returns true if" do
    ShopifyApp.configuration.embedded_app = true
    ShopifyApp.configuration.allow_jwt_authentication = false
    stubs(:user_agent_can_partition_cookies).returns(true)

    assert should_set_test_cookie?
  end
end
