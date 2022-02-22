# frozen_string_literal: true

require "test_helper"
require "utils/generated_sources"
require "generators/shopify_app/home_controller/home_controller_generator"
require "generators/shopify_app/authenticated_controller/authenticated_controller_generator"
require "dummy/app/controllers/application_controller"

class HomeControllerGeneratorWithExecutionTest < ActiveSupport::TestCase
  test "generates valid HomeController class" do
    with_home_controller do
      assert(HomeController < ApplicationController)
      assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
    end
  end

  test "generates valid HomeController class with authentication" do
    with_home_controller(authenticated: true) do
      assert(defined?(HomeController))
      assert(HomeController < AuthenticatedController)
      assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
    end
  end

  test "generates HomeController which fetches products and webhooks" do
    with_home_controller(authenticated: true) do |sources|
      controller = sources.controller(HomeController)

      stub_request(:get, "https://my-shop/admin/api/unstable/products.json?limit=10")
        .to_return(status: 200, body: "{\"products\":[]}", headers: {})

      stub_request(:get, "https://my-shop/admin/api/unstable/webhooks.json")
        .to_return(status: 200, body: "{}", headers: {})

      controller.index
    end
  end

  private

  def with_home_controller(authenticated: false, &block)
    Utils::GeneratedSources.with_session(self) do |sources|
      sources.run_generator(ShopifyApp::Generators::AuthenticatedControllerGenerator)
      sources.run_generator(ShopifyApp::Generators::HomeControllerGenerator,
        authenticated ? ["--with_cookie_authentication"] : [])

      refute(defined?(HomeController))

      sources.load_generated_classes("app/controllers/authenticated_controller.rb") if authenticated
      sources.load_generated_classes("app/controllers/home_controller.rb")

      assert(defined?(HomeController))

      block.call(sources)
    end
  end
end
