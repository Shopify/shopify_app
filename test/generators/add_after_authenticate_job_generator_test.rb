# frozen_string_literal: true
require 'test_helper'
require 'generators/shopify_app/add_after_authenticate_job/add_after_authenticate_job_generator'

class AddAfterAuthenticateJobGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddAfterAuthenticateJobGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
  end

  test 'adds enable_after_authenticate_actions config' do
    provide_existing_initializer_file

    run_generator

    assert_file "config/initializers/shopify_app.rb" do |config|
      assert_match 'config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }', config
    end
  end

  test "adds the after_authenticate job" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/jobs/shopify"
    assert_file "app/jobs/shopify/after_authenticate_job.rb"
  end
end
