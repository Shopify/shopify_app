require 'test_helper'

class ShopifyApp::ScripttagsManagerJobTest < ActiveSupport::TestCase
  test "#perform creates scripttags" do
    token = 'token'
    domain = 'example-app.com'

    ShopifyAPI::Session.expects(:temp).with(domain, token).yields

    manager = mock('manager')
    manager.expects(:create_scripttags)
    ShopifyApp::ScripttagsManager.expects(:new).with([], domain).returns(manager)

    job = ShopifyApp::ScripttagsManagerJob.new
    job.perform(shop_domain: domain, shop_token: token, scripttags: [])
  end
end
