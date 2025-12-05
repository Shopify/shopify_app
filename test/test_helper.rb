# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
require "rails/test_help"
require "mocha/minitest"

require "webmock/minitest"
require "byebug"
require "pry-nav"

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
    ShopifyApp.configuration.log_level = :warn
    ActiveSupport::Deprecation.silenced = true
  end

  def mock_session(shop: "my-shop.myshopify.com", scope: ShopifyApp.configuration.scope)
    mock_session = mock
    mock_session.stubs(:shop).returns(shop)
    mock_session.stubs(:access_token).returns("a-new-user_token!")
    mock_session.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new(scope))
    mock_session.stubs(:shopify_session_id).returns(1)
    mock_session.stubs(:expires).returns(nil)
    mock_session.stubs(:expired?).returns(false)

    mock_session
  end

  ##
  # If a test fails with this assertion it means the behavior should now be removed from the codebase.
  # The deprecation schedule gives users time to upgrade before the functionality can safely removed.
  def assert_within_deprecation_schedule(version_number)
    assert Gem::Version.create(ShopifyApp::VERSION) < Gem::Version.create(version_number)
  end
end
