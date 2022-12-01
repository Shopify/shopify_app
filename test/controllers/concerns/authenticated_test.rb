# frozen_string_literal: true

require "test_helper"

class AuthenticatedTest < ActionController::TestCase
  class AuthenticatedTestController < ActionController::Base
    include ShopifyApp::Authenticated

    def index
    end
  end

  tests AuthenticatedTestController

  test "includes all the needed concerns" do
    AuthenticatedTestController.include?(ShopifyApp::Localization)
    AuthenticatedTestController.include?(ShopifyApp::LoginProtection)
    AuthenticatedTestController.include?(ShopifyApp::CsrfProtection)
    AuthenticatedTestController.include?(ShopifyApp::EmbeddedApp)
    AuthenticatedTestController.include?(ShopifyApp::EnsureBilling)
  end

  test "detects deprecation message" do
    parent_deprecation_setting = ActiveSupport::Deprecation.silenced
    ActiveSupport::Deprecation.silenced = false
    ShopifyAPI::Context.stubs(:log_level).returns(:warn)

    assert_deprecated(/Authenticated has been replaced by EnsureHasSession./) do
      Class.new(ApplicationController) do
        include ShopifyApp::Authenticated
      end
    end

    ActiveSupport::Deprecation.silenced = parent_deprecation_setting
  end
end
