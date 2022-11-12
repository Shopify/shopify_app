# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"

class EnsureBillingTest < ActionController::TestCase
  class BillingTestController < ActionController::Base
    include ShopifyApp::LoginProtection
    include ShopifyApp::EnsureBilling

    def index
      render(html: "<h1>Success</ h1>")
    end
  end

  tests BillingTestController

  SHOP = "my-shop.myshopify.com"
  TEST_CHARGE_NAME = "Test charge"

  setup do
    Rails.application.routes.draw do
      get "/billing", to: "ensure_billing_test/billing_test#index"
    end

    @session = ShopifyAPI::Auth::Session.new(
      id: "1234",
      shop: SHOP,
      access_token: "access-token",
      scope: ["read_products"],
    )
    @controller.stubs(:current_shopify_session).returns(@session)

    @api_version = ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION
    ShopifyApp.configuration.api_version = @api_version
    ShopifyAppConfigurer.setup_context
  end

  test "requires single payment if none exists and non recurring" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_ONE_TIME,
    )
    stub_graphql_requests(
      { request_body: /oneTimePurchases/, response_body: EMPTY_SUBSCRIPTIONS },
      {
        request_body: hash_including({
          query: /appPurchaseOneTimeCreate/,
          variables: hash_including({ name: TEST_CHARGE_NAME }),
        }),
        response_body: PURCHASE_ONE_TIME_RESPONSE,
      },
    )

    get :index

    assert_client_side_redirection "https://totally-real-url"

    get :index, xhr: true

    assert_response :unauthorized
    assert_match "1", response.headers["X-Shopify-API-Request-Failure-Reauthorize"]
    assert_match(%r{^https://totally-real-url}, response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"])
  end

  test "requires subscription if none exists and recurring" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_EVERY_30_DAYS,
    )
    stub_graphql_requests(
      { request_body: /activeSubscriptions/, response_body: EMPTY_SUBSCRIPTIONS },
      {
        request_body: hash_including({
          query: /appSubscriptionCreate/,
          variables: hash_including({
            name: TEST_CHARGE_NAME,
            lineItems: {
              plan: {
                appRecurringPricingDetails: hash_including({
                  interval: ShopifyApp::BillingConfiguration::INTERVAL_EVERY_30_DAYS,
                }),
              },
            },
          }),
        }),
        response_body: PURCHASE_SUBSCRIPTION_RESPONSE,
      },
    )

    get :index

    assert_client_side_redirection "https://totally-real-url"

    get :index, xhr: true

    assert_response :unauthorized
    assert_match "1", response.headers["X-Shopify-API-Request-Failure-Reauthorize"]
    assert_match(%r{^https://totally-real-url}, response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"])
  end

  test "does not require single payment if exists and non recurring" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_ONE_TIME,
    )
    stub_graphql_requests({ request_body: /oneTimePurchases/, response_body: EXISTING_ONE_TIME_PAYMENT })

    get :index

    assert_response :success

    get :index, xhr: true

    assert_response :success
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize"].present?
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"].present?
  end

  test "does not require subscription if exists and recurring" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_ANNUAL,
    )
    stub_graphql_requests({ request_body: /activeSubscriptions/, response_body: EXISTING_SUBSCRIPTION })

    get :index

    assert_response :success

    get :index, xhr: true

    assert_response :success
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize"].present?
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"].present?
  end

  test "ignores non active one time payments" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_ONE_TIME,
    )
    stub_graphql_requests(
      { request_body: /oneTimePurchases/, response_body: EXISTING_INACTIVE_ONE_TIME_PAYMENT },
      {
        request_body: hash_including({
          query: /appPurchaseOneTimeCreate/,
          variables: hash_including({ name: TEST_CHARGE_NAME }),
        }),
        response_body: PURCHASE_ONE_TIME_RESPONSE,
      },
    )

    get :index

    assert_client_side_redirection "https://totally-real-url"

    get :index, xhr: true

    assert_response :unauthorized
    assert_match "1", response.headers["X-Shopify-API-Request-Failure-Reauthorize"]
    assert_match(%r{^https://totally-real-url}, response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"])
  end

  test "paginates until a payment is found" do
    ShopifyApp.configuration.billing = ShopifyApp::BillingConfiguration.new(
      charge_name: TEST_CHARGE_NAME,
      amount: 5,
      interval: ShopifyApp::BillingConfiguration::INTERVAL_ONE_TIME,
    )
    stub_graphql_requests(
      {
        request_body: hash_including({
          query: /oneTimePurchases/,
          variables: { endCursor: nil },
        }),
        response_body: EXISTING_ONE_TIME_PAYMENT_WITH_PAGINATION[0],
      },
      {
        request_body: hash_including({
          query: /oneTimePurchases/,
          variables: { endCursor: "end_cursor" },
        }),
        response_body: EXISTING_ONE_TIME_PAYMENT_WITH_PAGINATION[1],
      },
    )

    get :index

    assert_response :success

    get :index, xhr: true

    assert_response :success
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize"].present?
    refute response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"].present?
  end

  private

  def assert_client_side_redirection(url)
    assert_response :success
    assert_match "Redirecting", response.body
    assert_match(url, response.body)
  end

  def stub_graphql_requests(*requests)
    requests.each do |request|
      stub_request(:post, "https://my-shop.myshopify.com/admin/api/#{@api_version}/graphql.json")
        .with(
          body: request[:request_body],
          headers: { "X-Shopify-Access-Token": "access-token" },
        )
        .to_return(
          status: 200,
          body: JSON.dump(request[:response_body]),
        )
    end
  end

  EMPTY_SUBSCRIPTIONS = {
    data: {
      currentAppInstallation: {
        oneTimePurchases: {
          edges: [],
          pageInfo: { hasNextPage: false, endCursor: nil },
        },
        activeSubscriptions: [],
        userErrors: {},
      },
    },
  }

  EXISTING_ONE_TIME_PAYMENT = {
    data: {
      currentAppInstallation: {
        oneTimePurchases: {
          edges: [
            {
              node: {
                name: TEST_CHARGE_NAME,
                test: true, status: "ACTIVE",
              },
            },
          ],
          pageInfo: { hasNextPage: false, endCursor: nil },
        },
        activeSubscriptions: [],
      },
    },
  }

  EXISTING_ONE_TIME_PAYMENT_WITH_PAGINATION = [
    {
      data: {
        currentAppInstallation: {
          oneTimePurchases: {
            edges: [
              {
                node: { name: "some_other_name", test: true, status: "ACTIVE" },
              },
            ],
            pageInfo: { hasNextPage: true, endCursor: "end_cursor" },
          },
          activeSubscriptions: [],
        },
      },
    },
    {
      data: {
        currentAppInstallation: {
          oneTimePurchases: {
            edges: [
              {
                node: {
                  name: TEST_CHARGE_NAME,
                  test: true,
                  status: "ACTIVE",
                },
              },
            ],
            pageInfo: { hasNextPage: false, endCursor: nil },
          },
          activeSubscriptions: [],
        },
      },
    },
  ]

  EXISTING_INACTIVE_ONE_TIME_PAYMENT = {
    data: {
      currentAppInstallation: {
        oneTimePurchases: {
          edges: [
            {
              node: {
                name: TEST_CHARGE_NAME,
                test: true,
                status: "PENDING",
              },
            },
          ],
          pageInfo: { hasNextPage: false, endCursor: nil },
        },
        activeSubscriptions: [],
      },
    },
  }

  EXISTING_SUBSCRIPTION = {
    data: {
      currentAppInstallation: {
        oneTimePurchases: {
          edges: [],
          pageInfo: { hasNextPage: false, endCursor: nil },
        },
        activeSubscriptions: [{ name: TEST_CHARGE_NAME, test: true }],
      },
    },
  }

  PURCHASE_ONE_TIME_RESPONSE = {
    data: {
      appPurchaseOneTimeCreate: {
        confirmationUrl: "https://totally-real-url",
        userErrors: {},
      },
    },
  }

  PURCHASE_SUBSCRIPTION_RESPONSE = {
    data: {
      appSubscriptionCreate: {
        confirmationUrl: "https://totally-real-url",
        userErrors: {},
      },
    },
  }
end
