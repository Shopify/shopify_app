require 'test_helper'
require 'generators/shopify_app/home_controller/home_controller_generator'

class HomeControllerGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::HomeControllerGenerator
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

  test "creates the home controller" do
    run_generator
    assert_file "app/controllers/home_controller.rb"
  end

  test "creates the home index view with embedded false" do
    ShopifyApp.configuration.embedded_app = false
    run_generator
    refute File.exist?('app/javascript/shopify_app/shopify_app.js')
  end

  test "adds home route to routes" do
    run_generator
    assert_file "config/routes.rb" do |routes|
      assert_match "mount ShopifyApp::Engine, at: '/'", routes
      assert_match "root :to => 'home#index'", routes
    end
  end
end
