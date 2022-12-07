# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"
require "action_view/testing/resolvers"

class ItpTest < ActionController::TestCase
  test "detects deprecation notice" do
    message = "Itp will be removed in an upcoming version"
    version = "22.0.0"

    ShopifyApp::Logger.expects(:deprecated).with(message, version)

    Class.new(ApplicationController) do
      include ShopifyApp::Itp
    end

    assert_within_deprecation_schedule(version)
  end
end
