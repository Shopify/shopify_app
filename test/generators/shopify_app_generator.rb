# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/generators/shopify_app/shopify_app_generator"

class ShopifyAppGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ShopifyAppGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    # Stub the generate method to avoid calling bin/rails
    ShopifyApp::Generators::ShopifyAppGenerator.any_instance.stubs(:generate)
  end

  test "shopify_app_generator runs" do
    run_generator
  end
end
