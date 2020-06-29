# frozen_string_literal: true

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
    AuthenticatedTestController.include?(ShopifyApp::AccessTokenHeaders)
  end
end
