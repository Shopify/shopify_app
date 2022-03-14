# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/routes/routes_generator"

class ControllerGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::RoutesGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_routes_file
  end

  test "copies ShopifyApp routes to the host application" do
    run_generator

    assert_file "config/routes.rb" do |routes|
      assert_match "get 'login' => :new, :as => :login", routes
      assert_match "post 'login' => :create, :as => :authenticate", routes
      assert_match "get 'auth/shopify/callback' => :callback", routes
      assert_match "get 'logout' => :destroy, :as => :logout", routes
      refute_match "mount ShopifyApp::Engine, at: '/'", routes
    end
  end
end
