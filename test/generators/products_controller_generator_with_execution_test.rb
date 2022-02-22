# frozen_string_literal: true

require "test_helper"
require "utils/rails_generator_runtime"
require "generators/shopify_app/products_controller/products_controller_generator"
require "generators/shopify_app/authenticated_controller/authenticated_controller_generator"
require "dummy/app/controllers/application_controller"

class ProductsControllerGeneratorWithExecutionTest < ActiveSupport::TestCase
  test "generates valid ProductController class" do
    with_products_controller do
      assert(ProductsController < AuthenticatedController)
    end
  end

  test "generates ProductController which fetches products" do
    with_products_controller do |sources|
      controller = sources.controller(ProductsController)

      def controller.render(json:)
        raise "Invalid JSON provided: #{json}" unless json == { products: [] }
      end

      stub_request(:get, "https://my-shop/admin/api/unstable/products.json?limit=10")
        .to_return(status: 200, body: "{\"products\":[]}", headers: {})

      controller.index
    end
  end

  private

  def with_products_controller(&block)
    Utils::RailsGeneratorRuntime.with_session(self) do |sources|
      sources.run_generator(ShopifyApp::Generators::AuthenticatedControllerGenerator)
      sources.run_generator(ShopifyApp::Generators::ProductsControllerGenerator)

      refute(defined?(ProductsController))

      sources.load_generated_classes("app/controllers/authenticated_controller.rb")
      sources.load_generated_classes("app/controllers/products_controller.rb")

      assert(defined?(ProductsController))

      block.call(sources)
    end
  end
end
