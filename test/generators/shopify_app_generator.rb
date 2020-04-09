# frozen_string_literal: true
require 'test_helper'
require 'generators/shopify_app/shopify_app_generator'

class ShopifyAppGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ShopifyAppGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  test "shopify_app_generator runs" do
    run_generator
  end
end
