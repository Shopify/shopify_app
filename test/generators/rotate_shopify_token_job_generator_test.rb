# typed: false
# frozen_string_literal: true

require 'test_helper'
require 'generators/shopify_app/rotate_shopify_token_job/rotate_shopify_token_job_generator'

class RotateShopifyTokenJobGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::RotateShopifyTokenJobGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    run_generator
  end

  test "adds the rotate_shopify_token job" do
    assert_directory "app/jobs/shopify"
    assert_file "app/jobs/shopify/rotate_shopify_token_job.rb"
  end

  test "adds the rotate_shopify_token rake task" do
    assert_directory "lib/tasks/shopify"
    assert_file "lib/tasks/shopify/rotate_shopify_token.rake"
  end
end
