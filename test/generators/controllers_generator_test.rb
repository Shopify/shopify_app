# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/controllers/controllers_generator"

class ControllersGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ControllersGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  test "copies ShopifyApp controllers to the host application" do
    run_generator
    assert_directory "app/controllers"
    assert_file "app/controllers/shopify_app/sessions_controller.rb"
    assert_file "app/controllers/shopify_app/authenticated_controller.rb"
  end
end
