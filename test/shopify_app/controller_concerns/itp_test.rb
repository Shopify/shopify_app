# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"
require "action_view/testing/resolvers"

class ItpTest < ActionController::TestCase
  test "detects deprecation notice" do
    parent_deprecation_setting = ActiveSupport::Deprecation.silenced
    ActiveSupport::Deprecation.silenced = false
    ShopifyAPI::Context.stubs(:log_level).returns(:warn)
    assert_deprecated(/Itp will be removed/) do
      Class.new(ApplicationController) do
        include ShopifyApp::Itp
      end
    end
    ActiveSupport::Deprecation.silenced = parent_deprecation_setting
  end
end
