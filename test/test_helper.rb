# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"
require "byebug"
require "pry"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  include GeneratorTestHelpers
  include SessionStoreStrategyTestHelpers
  include AccessScopesStrategyHelpers

  API_META_TEST_RESPONSE = <<~JSON
    {
      "apis": [{
        "handle": "admin",
        "versions": [{
          "handle": "2019-07",
          "display_name": "2019-07",
          "supported": true,
          "latest_supported": false
        },{
            "handle": "2019-10",
            "latest_supported": true,
            "display_name": "2019-10",
            "supported": true
          }]
        }]
      }
  JSON

  def before_setup
    super
    WebMock.disable_net_connect!
    WebMock.stub_request(:get, "https://app.shopify.com/services/apis.json").to_return(body: API_META_TEST_RESPONSE)
    ShopifyApp::InMemorySessionStore.clear
    ShopifyAppConfigurer.call
    Rails.application.reload_routes!
  end

  def mock_session(shop: "my-shop.myshopify.com", scope: ShopifyApp.configuration.scope)
    mock_session = mock
    mock_session.stubs(:shop).returns(shop)
    mock_session.stubs(:access_token).returns("a-new-user_token!")
    mock_session.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new(scope))

    mock_session
  end
end
