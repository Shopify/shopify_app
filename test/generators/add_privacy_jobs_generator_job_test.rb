# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/add_privacy_jobs/add_privacy_jobs_generator"

class AddPrivacyJobsGeneratorJobTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddPrivacyJobsGenerator
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

  test "creates app uninstalled job file" do
    run_generator

    assert_file "app/jobs/customers_data_request_job.rb"
    assert_file "app/jobs/shop_redact_job.rb"
    assert_file "app/jobs/customers_redact_job.rb"
  end
end
