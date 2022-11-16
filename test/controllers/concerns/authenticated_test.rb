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
    ActiveSupport::Deprecation.expects(:warn).with(
      "[22.0.0] [ ShopifyApp | WARN | Shop Not Found ] "\
      "Authenticated has been replaced by to EnsureHasSession. "\
      "Please use EnsureHasSession controller concern for the same behavior")

    Class.new(ApplicationController) do
      include ShopifyApp::Authenticated
    end
  end
end
