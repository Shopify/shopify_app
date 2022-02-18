# frozen_string_literal: true

require "test_helper"
require "test_helpers/fake_session_storage"
require "utils/generated_sources"
require "generators/shopify_app/products_controller/products_controller_generator"
require "generators/shopify_app/authenticated_controller/authenticated_controller_generator"
require "dummy/app/controllers/application_controller"

class ProductsControllerGeneratorWithExecutionTest < ActiveSupport::TestCase
  test "generates valid ProductController class" do
    with_products_controller do
      assert(defined?(ProductsController))
      assert(ProductsController < AuthenticatedController)
    end
  end

  test "generates ProductController which fetches products" do
    with_products_controller do
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
      controller = ProductsController.new

      def controller.current_shopify_session
        ShopifyAPI::Auth::Session.new(shop: "my-shop")
      end

      def controller.render(json:)
        raise "Invalid JSON provided: #{json}" unless json == {products: []}
      end

      stub_request(:get, "https://my-shop/admin/api/unstable/products.json?limit=10")
        .to_return(status: 200, body: "{\"products\":[]}", headers: {})    

      controller.index
    end
  end

  private

  def with_products_controller(&block)
    WebMock.enable!
    sources = Utils::GeneratedSources.new
    sources.run_generator(ShopifyApp::Generators::AuthenticatedControllerGenerator)
    sources.run_generator(ShopifyApp::Generators::ProductsControllerGenerator)

    refute(defined?(ProductsController))
    
    sources.load_generated_classes("app/controllers/authenticated_controller.rb")
    sources.load_generated_classes("app/controllers/products_controller.rb")
    block.call(sources)
  ensure
    WebMock.reset!
    WebMock.disable!
    sources.clear
  end
end