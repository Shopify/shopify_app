require 'test_helper'

class ShopifyApp::ScripttagsManagerJobTest < ActiveSupport::TestCase
  test "#perform creates scripttags" do
    token = 'token'
    domain = 'example-app.com'
    api_version = :unstable

    ShopifyAPI::Session
      .expects(:temp)
      .with(domain: domain, token: token, api_version: api_version)
      .yields

    manager = mock('manager')
    manager.expects(:create_scripttags)
    ShopifyApp::ScripttagsManager.expects(:new).with([], domain).returns(manager)

    job = ShopifyApp::ScripttagsManagerJob.new
    job.perform(shop_domain: domain, shop_token: token, scripttags: [])
  end
end
