# frozen_string_literal: true
require 'test_helper'

class OrderUpdateJob < ActiveJob::Base
  def perform; end
end

module ShopifyApp
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      WebhooksController.any_instance.stubs(:verify_request).returns(true)
      WebhooksController.any_instance.stubs(:webhook_namespace).returns(nil)
    end

    test "receives webhook and performs job" do
      send_webhook 'order_update', { foo: :bar }
      assert_response :ok
      assert_enqueued_jobs 1
    end

    test "passes webhook to the job" do
      webhook = { 'foo' => 'bar' }
      job_args = { shop_domain: "test.myshopify.com", webhook: webhook }

      perform_later_stub = mock('perform_later')
      perform_later_stub.expects(:perform_later).with(job_args)
      OrderUpdateJob.expects(:set).with(wait: 0).returns(perform_later_stub)

      send_webhook 'order_update', webhook
      assert_response :ok
    end

    test "sets a job timeout if the configuration is set" do
      WebhooksController.any_instance.stubs(:webhook_job_delay).returns(10)

      webhook = { 'foo' => 'bar' }
      job_args = { shop_domain: 'test.myshopify.com', webhook: webhook }

      perform_later_stub = mock('perform_later')
      perform_later_stub.expects(:perform_later).with(job_args)
      OrderUpdateJob.expects(:set).with(wait: 10).returns(perform_later_stub)

      send_webhook 'order_update', webhook
      assert_response :ok
    end

    test "returns error for webhook with no job class" do
      assert_raises ShopifyApp::MissingWebhookJobError do
        send_webhook 'test', { foo: :bar }
      end
    end

    private

    def send_webhook(name, data)
      post(shopify_app.webhooks_path(name), params: data,
           headers: { 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => 'test.myshopify.com' })
    end
  end
end
