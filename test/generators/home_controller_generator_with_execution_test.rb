# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../utils/rails_generator_runtime"
require_relative "../../lib/generators/shopify_app/home_controller/home_controller_generator"
require_relative "../../lib/generators/shopify_app/authenticated_controller/authenticated_controller_generator"
require_relative "../dummy/app/controllers/application_controller"

class HomeControllerGeneratorWithExecutionTest < ActiveSupport::TestCase
  test "generates authenticated HomeController class if not embedded" do
    assert_home_controller_is_authenticated(is_embedded: false)
  end

  test "generates valid embedded HomeController class" do
    with_home_controller(is_embedded: true) do
      refute(defined?(AuthenticatedController))
      assert(HomeController < ApplicationController)
      assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
    end
  end

  test "generates HomeController which fetches products and webhooks" do
    with_home_controller(is_embedded: false) do
      controller = HomeController.new

      stub_request(:get, "https://my-shop/admin/api/#{ShopifyApp.configuration.api_version}/products.json?limit=10")
        .to_return(status: 200, body: "{\"products\":[]}", headers: {})

      stub_request(:get, "https://my-shop/admin/api/#{ShopifyApp.configuration.api_version}/webhooks.json")
        .to_return(status: 200, body: "{}", headers: {})

      controller.index
    end
  end

  private

  def assert_home_controller_is_authenticated(is_embedded:)
    with_home_controller(is_embedded: is_embedded) do
      assert(HomeController < AuthenticatedController)
      assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
    end
  end

  def with_home_controller(is_embedded:, &block)
    Utils::RailsGeneratorRuntime.with_session(self, is_embedded: is_embedded) do |runtime|
      home_controller_generator_options = []
      home_controller_generator_options += ["--embedded", "false"] unless is_embedded

      generates_authenticated_controller = !is_embedded

      refute(defined?(HomeController))

      if generates_authenticated_controller
        runtime.run_generator(ShopifyApp::Generators::AuthenticatedControllerGenerator)
      end

      # Stub the generate method to avoid calling bin/rails
      ShopifyApp::Generators::HomeControllerGenerator.any_instance.stubs(:generate)
      runtime.run_generator(ShopifyApp::Generators::HomeControllerGenerator, home_controller_generator_options)

      assert(defined?(HomeController))

      block.call(runtime)
    end
  end
end
