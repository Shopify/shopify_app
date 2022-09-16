# frozen_string_literal: true

module ShopifyApp
  module EnsureBilling
    extend ActiveSupport::Concern

    RECURRING_INTERVALS = [BillingConfiguration::INTERVAL_EVERY_30_DAYS, BillingConfiguration::INTERVAL_ANNUAL]

    included do
      before_action :check_billing, if: :billing_required?
      rescue_from ::ShopifyApp::BillingError, with: :handle_billing_error
    end

    private

    def check_billing(session = current_shopify_session)
      return true if session.blank? || !billing_required?

      confirmation_url = nil

      if has_active_payment?(session)
        has_payment = true
      else
        has_payment = false
        confirmation_url = request_payment(session)
      end

      unless has_payment
        if request.xhr?
          add_top_level_redirection_headers(url: confirmation_url, ignore_response_code: true)
          head(:unauthorized)
        else
          redirect_to(confirmation_url, allow_other_host: true)
        end
      end

      has_payment
    end

    def billing_required?
      ShopifyApp.configuration.requires_billing?
    end

    def handle_billing_error(error)
      logger.info("#{error.message}: #{error.errors}")
      redirect_to_login
    end

    def has_active_payment?(session)
      if recurring?
        has_subscription?(session)
      else
        has_one_time_payment?(session)
      end
    end

    def has_subscription?(session)
      response = run_query(session: session, query: RECURRING_PURCHASES_QUERY)
      subscriptions = response.body["data"]["currentAppInstallation"]["activeSubscriptions"]

      subscriptions.each do |subscription|
        if subscription["name"] == ShopifyApp.configuration.billing.charge_name &&
            (!Rails.env.production? || !subscription["test"])

          return true
        end
      end

      false
    end

    def has_one_time_payment?(session)
      purchases = nil
      end_cursor = nil

      loop do
        response = run_query(session: session, query: ONE_TIME_PURCHASES_QUERY, variables: { endCursor: end_cursor })
        purchases = response.body["data"]["currentAppInstallation"]["oneTimePurchases"]

        purchases["edges"].each do |purchase|
          node = purchase["node"]

          if node["name"] == ShopifyApp.configuration.billing.charge_name &&
              (!Rails.env.production? || !node["test"]) &&
              node["status"] == "ACTIVE"

            return true
          end
        end

        end_cursor = purchases["pageInfo"]["endCursor"]
        break unless purchases["pageInfo"]["hasNextPage"]
      end

      false
    end

    def request_payment(session)
      shop = session.shop
      host = Base64.encode64("#{shop}/admin")
      return_url = "https://#{ShopifyAPI::Context.host_name}?shop=#{shop}&host=#{host}"

      if recurring?
        data = request_recurring_payment(session: session, return_url: return_url)
        data = data["data"]["appSubscriptionCreate"]
      else
        data = request_one_time_payment(session: session, return_url: return_url)
        data = data["data"]["appPurchaseOneTimeCreate"]
      end

      raise BillingError.new("Error while billing the store", data["userErrros"]) unless data["userErrors"].empty?

      data["confirmationUrl"]
    end

    def request_recurring_payment(session:, return_url:)
      response = run_query(
        session: session,
        query: RECURRING_PURCHASE_MUTATION,
        variables: {
          name: ShopifyApp.configuration.billing.charge_name,
          lineItems: {
            plan: {
              appRecurringPricingDetails: {
                interval: ShopifyApp.configuration.billing.interval,
                price: {
                  amount: ShopifyApp.configuration.billing.amount,
                  currencyCode: ShopifyApp.configuration.billing.currency_code,
                },
              },
            },
          },
          returnUrl: return_url,
          test: !Rails.env.production?,
        }
      )

      response.body
    end

    def request_one_time_payment(session:, return_url:)
      response = run_query(
        session: session,
        query: ONE_TIME_PURCHASE_MUTATION,
        variables: {
          name: ShopifyApp.configuration.billing.charge_name,
          price: {
            amount: ShopifyApp.configuration.billing.amount,
            currencyCode: ShopifyApp.configuration.billing.currency_code,
          },
          returnUrl: return_url,
          test: !Rails.env.production?,
        }
      )

      response.body
    end

    def recurring?
      RECURRING_INTERVALS.include?(ShopifyApp.configuration.billing.interval)
    end

    def run_query(session:, query:, variables: nil)
      client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)

      response = client.query(query: query, variables: variables)

      raise BillingError.new("Error while billing the store", []) unless response.ok?
      raise BillingError.new("Error while billing the store", response.body["errors"]) if response.body["errors"]

      response
    end

    RECURRING_PURCHASES_QUERY = <<~'QUERY'
      query appSubscription {
        currentAppInstallation {
          activeSubscriptions {
            name, test
          }
        }
      }
    QUERY

    ONE_TIME_PURCHASES_QUERY = <<~'QUERY'
      query appPurchases($endCursor: String) {
        currentAppInstallation {
          oneTimePurchases(first: 250, sortKey: CREATED_AT, after: $endCursor) {
            edges {
              node {
                name, test, status
              }
            }
            pageInfo {
              hasNextPage, endCursor
            }
          }
        }
      }
    QUERY

    RECURRING_PURCHASE_MUTATION = <<~'QUERY'
      mutation createPaymentMutation(
        $name: String!
        $lineItems: [AppSubscriptionLineItemInput!]!
        $returnUrl: URL!
        $test: Boolean
      ) {
        appSubscriptionCreate(
          name: $name
          lineItems: $lineItems
          returnUrl: $returnUrl
          test: $test
        ) {
          confirmationUrl
          userErrors {
            field, message
          }
        }
      }
    QUERY

    ONE_TIME_PURCHASE_MUTATION = <<~'QUERY'
      mutation createPaymentMutation(
        $name: String!
        $price: MoneyInput!
        $returnUrl: URL!
        $test: Boolean
      ) {
        appPurchaseOneTimeCreate(
          name: $name
          price: $price
          returnUrl: $returnUrl
          test: $test
        ) {
          confirmationUrl
          userErrors {
            field, message
          }
        }
      }
    QUERY
  end
end
