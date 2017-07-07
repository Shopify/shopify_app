require 'test_helper'
require 'generators/shopify_app/enable_after_authenticate_actions/enable_after_authenticate_actions_generator'

class EnableAfterAuthenticateActionsGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::EnableAfterAuthenticateActionsGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
  end

  test 'adds enable_after_authenticate_actions config' do
    provide_existing_initializer_file

    run_generator

    assert_file "config/initializers/shopify_app.rb" do |config|
      assert_match 'config.enable_after_authenticate_actions = true', config
    end
  end

  test "adds the after_authenticate job" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/jobs/shopify"
    assert_file "app/jobs/shopify/after_authenticate_job.rb"
  end
end
