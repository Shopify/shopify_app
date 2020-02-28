require 'test_helper'

class ShopifyApp::SameSiteCookieMiddlewareTest < ActiveSupport::TestCase 
  INCOMPATIBLE_USER_AGENTS = [
    "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)"\
      " GSA/87.0.279142407 Mobile/15E148 Safari/605.1",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko)"\
      " Version/12.1.2 Safari/605.1.15",
    "Mozilla/5.0 (Linux; U; Android 7.0; en-US; SM-G935F Build/NRD90M) AppleWebKit/534.30 (KHTML, like Gecko) "\
      "Version/4.0 UCBrowser/11.3.8.976 U3/0.8.0 Mobile Safari/534.30",
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
  ]

  COMPATIBLE_USER_AGENTS.each do |user_agent|
    test "user agent #{user_agent} is correctly marked as incompatible" do
      refute ShopifyApp::SameSiteCookieMiddleware.same_site_none_incompatible?(user_agent)
    end
  end

  def app
    app = Rack::Lint.new(lambda { |env|
      req = Rack::Request.new(env)

      response = Rack::Response.new("", 200, "Content-Type" => "text/yaml")
    
      response.set_cookie("session_test", { value: "session_test", domain: ".test.com", path: "/" })
      response.finish
    })
  end

  def env_for_url(url)
    env = Rack::MockRequest.env_for(url)
    env['HTTP_USER_AGENT'] = COMPATIBLE_USER_AGENTS.first
    env
  end

  def middleware
    ShopifyApp.configuration.stubs(:enable_same_site_none).returns(true)
      
    ShopifyApp::SameSiteCookieMiddleware.new(app)
  end

  test 'SameSite cookie attributes should be added on SSL' do
    env = env_for_url("https://test.com/")
    
    status, headers, body = middleware.call(env)

    assert_includes headers['Set-Cookie'], 'SameSite'
  end

  test 'SameSite cookie attributes should not be added on non SSL requests' do
    env = env_for_url("http://test.com/")
    
    status, headers, body = middleware.call(env)

    assert_not_includes headers['Set-Cookie'], 'SameSite'
  end
end
