# frozen_string_literal: true
require 'test_helper'

module ShopifyApp
  class ScripttagsManagerJobTest < ActiveSupport::TestCase
    test "#perform creates scripttags" do
      token = 'token'
      domain = 'example-app.com'

      ShopifyAPI::Auth::Session.expects(:temp)
        .with(shop: domain, access_token: token)
        .yields

      manager = mock('manager')
      manager.expects(:create_scripttags)
      ShopifyApp::ScripttagsManager.expects(:new).with([], domain).returns(manager)

      job = ShopifyApp::ScripttagsManagerJob.new
      job.perform(shop_domain: domain, shop_token: token, scripttags: [])
    end
  end
end
