# frozen_string_literal: true

require "test_helper"

class EnsureHasSessionTest < ActionController::TestCase
  class EnsureHasSessionTestController < ActionController::Base
    include ShopifyApp::EnsureHasSession

    def index
    end
  end

  tests EnsureHasSessionTestController

  test "includes all the needed concerns" do
    EnsureHasSessionTestController.include?(ShopifyApp::Localization)
    EnsureHasSessionTestController.include?(ShopifyApp::LoginProtection)
    EnsureHasSessionTestController.include?(ShopifyApp::CsrfProtection)
    EnsureHasSessionTestController.include?(ShopifyApp::EmbeddedApp)
    EnsureHasSessionTestController.include?(ShopifyApp::EnsureBilling)
  end
end
