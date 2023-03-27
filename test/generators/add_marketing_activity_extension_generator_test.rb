# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/add_marketing_activity_extension/add_marketing_activity_extension_generator"

class AddMarketingActivityExtensionGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddMarketingActivityExtensionGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  test "adds the extension controller" do
    provide_existing_routes_file

    run_generator

    assert_file "app/controllers/marketing_activities_controller.rb" do |controller|
      assert_match "class MarketingActivitiesController < ShopifyApp::ExtensionVerificationController", controller
    end
  end

  test "adds the endpoint routes to routes" do
    provide_existing_routes_file

    run_generator

    assert_file "config/routes.rb" do |routes|
      resource_declaration = "resource :marketing_activities, only: [:create, :update] do"
      routes_declarations = <<~EOS
        patch :resume
        patch :pause
        patch :delete
        post :republish
        post :preload_form_data
        post :preview
        post :errors
      EOS
      assert resource_declaration, routes
      assert routes_declarations, routes
    end
  end

  test "detect deprecation notice when generating controller" do
    message = "MarketingActivitiesController will be removed in an upcoming version"
    version = "22.0.0"
    ShopifyApp::Logger.expects(:deprecated).with(message, version)
    run_generator
    assert_within_deprecation_schedule(version)
  end
end
