require 'test_helper'

class ShopifyApp::SameSiteCookieMiddlewareTest < ActiveSupport::TestCase 
  INCOMPATIBLE_USER_AGENTS = [
    "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)"\
      " GSA/87.0.279142407 Mobile/15E148 Safari/605.1",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko)"\
      " Version/12.1.2 Safari/605.1.15",
    "Mozilla/5.0 (Linux; U; Android 7.0; en-US; SM-G935F Build/NRD90M) AppleWebKit/534.30 (KHTML, like Gecko) "\
      "Version/4.0 UCBrowser/11.3.8.976 U3/0.8.0 Mobile Safari/534.30",
    nil,
  ]

  INCOMPATIBLE_USER_AGENTS.each do |user_agent|
    test "user agent #{user_agent} is correctly marked as incompatible" do
      assert ShopifyApp::SameSiteCookieMiddleware.same_site_none_incompatible?(user_agent)
    end
  end

  COMPATIBLE_USER_AGENTS = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117"\
      " Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:72.0) Gecko/20100101 Firefox/72.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4"\
      " Safari/605.1.15",
    "Custom User Agent",
  ]

  COMPATIBLE_USER_AGENTS.each do |user_agent|
    test "user agent #{user_agent} is correctly marked as compatible" do
      refute ShopifyApp::SameSiteCookieMiddleware.same_site_none_incompatible?(user_agent)
    end
  end
end
