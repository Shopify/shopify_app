# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/generators/shopify_app/products_controller/products_controller_generator"

class ProductsControllerGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ProductsControllerGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    prepare_destination
    provide_existing_application_file
    provide_existing_routes_file
    provide_existing_application_controller
  end

  test "creates the products controller" do
    run_generator
    assert_file "app/controllers/products_controller.rb"
  end

  test "adds products route to routes" do
    run_generator
    assert_file "config/routes.rb" do |routes|
      assert_match "get '/products', :to => 'products#index'", routes
    end
  end
end
