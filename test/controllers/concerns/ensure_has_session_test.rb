# frozen_string_literal: true

require_relative "../../test_helper"

class EnsureHasSessionTest < ActionController::TestCase
  test "includes all the needed concerns" do
    ShopifyApp.configuration.stubs(:use_new_embedded_auth_strategy?).returns(false)

    controller = define_controller
    assert_common_concerns_are_included(controller)
    assert controller.include?(ShopifyApp::LoginProtection), "ShopifyApp::LoginProtection"
    refute controller.include?(ShopifyApp::TokenExchange), "ShopifyApp::TokenExchange"
  end

  test "includes TokenExchange when use_new_embedded_auth_strategy is true" do
    ShopifyApp.configuration.stubs(:use_new_embedded_auth_strategy?).returns(true)

    controller = define_controller
    assert_common_concerns_are_included(controller)
    assert controller.include?(ShopifyApp::TokenExchange), "ShopifyApp::TokenExchange"
    refute controller.include?(ShopifyApp::LoginProtection), "ShopifyApp::LoginProtection"
  end

  private

  def assert_common_concerns_are_included(controller)
    assert controller.include?(ShopifyApp::Localization), "ShopifyApp::Localization"
    assert controller.include?(ShopifyApp::CsrfProtection), "ShopifyApp::CsrfProtection"
    assert controller.include?(ShopifyApp::EmbeddedApp), "ShopifyApp::EmbeddedApp"
    assert controller.include?(ShopifyApp::EnsureBilling), "ShopifyApp::EnsureBilling"
  end

  def define_controller
    Class.new(ActionController::Base) do
      include ShopifyApp::EnsureHasSession
    end
  end
end
