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
    version = "22.0.0"
    ShopifyApp::Logger.expects(:deprecated).with(
      regexp_matches(/Authenticated has been replaced by EnsureHasSession./), version
    )
    ShopifyApp::Logger.stubs(:deprecated).with("Itp will be removed in an upcoming version", version)
    Class.new(ApplicationController) do
      include ShopifyApp::Authenticated
    end

    assert_within_deprecation_schedule(version)
  end
end
