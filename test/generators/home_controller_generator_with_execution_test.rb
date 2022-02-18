# frozen_string_literal: true

require "test_helper"
require "test_helpers/fake_session_storage"
require "utils/generated_sources"
require "generators/shopify_app/home_controller/home_controller_generator"
require "generators/shopify_app/controllers/controllers_generator"

class HomeControllerGeneratorWithExecutionTest < ActiveSupport::TestCase
  # test "generates valid HomeController class" do
  #   sources = Utils::GeneratedSources.new
  #   sources.run_generator(ShopifyApp::Generators::HomeControllerGenerator)

  #   refute(defined?(HomeController))
    
  #   sources.load_generated_classes("app/controllers/home_controller.rb")

  #   assert(defined?(HomeController))
  #   assert(HomeController < ApplicationController)
  #   assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
  # ensure
  #   sources.clear
  # end

  # test "generates valid HomeController class with authentication" do
  #   with_authenticated_home_controller do
  #     assert(defined?(HomeController))
  #     assert(HomeController < ShopifyApp::AuthenticatedController)
  #     assert(HomeController.include?(ShopifyApp::ShopAccessScopesVerification))
  #   end
  # end

  test "generates HomeController which fetches products and webhooks" do
    with_authenticated_home_controller do
      assert(defined?(ShopifyAPI))
      ShopifyAPI::Context.setup(
        api_key: "API_KEY",
        api_secret_key: "API_SECRET_KEY",
        api_version: "unstable",
        host_name: "app-address.com",
        scope: ["scope1", "scope2"],
        is_private: false,
        is_embedded: false,
        session_storage: TestHelpers::FakeSessionStorage.new,
        user_agent_prefix: nil
      )
      controller = HomeController.new
      controller.index
    end
  end

  private

  def with_authenticated_home_controller(&block)
    WebMock.enable!
    sources = Utils::GeneratedSources.new
    sources.run_generator(ShopifyApp::Generators::ControllersGenerator)
    sources.run_generator(ShopifyApp::Generators::HomeControllerGenerator,
      %w(--with_cookie_authentication))

    refute(defined?(HomeController))
    
    sources.load_generated_classes("app/controllers/shopify_app/authenticated_controller.rb")
    sources.load_generated_classes("app/controllers/home_controller.rb")
    block.call(sources)
  ensure
    WebMock.reset!
    WebMock.disable!
    sources.clear
  end
end