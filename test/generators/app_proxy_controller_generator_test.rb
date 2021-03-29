# frozen_string_literal: true
require "test_helper"
require "generators/shopify_app/app_proxy_controller/app_proxy_controller_generator"

class AppProxyControllerGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AppProxyControllerGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_routes_file
  end

  test "creates the app_proxy controller" do
    run_generator
    assert_file "app/controllers/app_proxy_controller.rb"
  end

  test "creates the app_proxy index view" do
    run_generator
    assert_file "app/views/app_proxy/index.html.erb"
  end

  test "adds app_proxy route to routes" do
    run_generator
    assert_file "config/routes.rb" do |routes|
      assert_match "mount ShopifyApp::Engine, at: \"/\"\n", routes
      assert "namespace :app_proxy do\n", routes
    end
  end
end
