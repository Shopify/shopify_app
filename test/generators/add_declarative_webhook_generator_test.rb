# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/add_declarative_webhook/add_declarative_webhook_generator"

class AddDeclarativeWebhookGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddDeclarativeWebhookGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  arguments ["--topic", "products/update", "--path", "webhooks/product_update"]

  setup do
    prepare_destination
  end

  test "adds the webhook job" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/jobs"
    assert_file "app/jobs/product_update_job.rb" do |job|
      assert_match "class ProductUpdateJob < ActiveJob::Base", job
    end
  end

  test "adds the webhook controller" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/controllers/webhooks"
    assert_file "app/controllers/webhooks/product_update_controller.rb" do |controller|
      assert_match "class ProductUpdateController < ApplicationController", controller
    end
  end

  test "adds new webhook route to existing route config" do
    provide_existing_routes_file

    run_generator

    assert_file "config/routes.rb" do |routes|
      assert_match "namespace :webhooks do", routes
      assert_match exisiting_webhook, routes
      assert_match new_webhook, routes
    end
  end

  def exisiting_webhook
    "post \"/app_uninstalled\", to: \"app_uninstalled#receive\"\n "
  end

  def new_webhook
    "post 'product_update', to: 'product_update#receive'"
  end
end
