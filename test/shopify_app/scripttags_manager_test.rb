require 'test_helper'

class ShopifyApp::ScripttagsManagerTest < ActiveSupport::TestCase

  setup do
    ShopifyApp.configure do |config|
      config.scripttags = [
        {event: 'onload', src: 'https://example-app.com/fancy.js'},
        {event: 'onload', src: 'https://example-app.com/foobar.js'}
      ]
    end

    @manager = ShopifyApp::ScripttagsManager.new("regular-shop.myshopify.com", "token")
  end

  test "#create_scripttags makes calls to create scripttags" do
    ShopifyAPI::ScriptTag.stubs(all: [])

    expect_scripttag_creation('onload', 'https://example-app.com/fancy.js')
    expect_scripttag_creation('onload', 'https://example-app.com/foobar.js')
    @manager.create_scripttags
  end

  test "#create_scripttags when creating a scripttag fails, raises an error" do
    ShopifyAPI::ScriptTag.stubs(all: [])
    scripttag = stub(persisted?: false, errors: stub(full_messages: ["Source needs to be https"]))
    ShopifyAPI::ScriptTag.stubs(create: scripttag)

    assert_raise ShopifyApp::ScripttagsManager::CreationFailed do
      @manager.create_scripttags
    end
  end

  test "#recreate_scripttags! destroys all scripttags and recreates" do
    @manager.expects(:destroy_scripttags)
    @manager.expects(:create_scripttags)

    @manager.recreate_scripttags!
  end

  test "#destroy_scripttags makes calls to destroy scripttags" do
    ShopifyAPI::ScriptTag.stubs(:all).returns(Array.wrap(all_mock_scripttags.first))
    ShopifyAPI::ScriptTag.expects(:delete).with(all_mock_scripttags.first.id)

    @manager.destroy_scripttags
  end

  test "#destroy_scripttags does not destroy scripttags that do not have a matching address" do
    ShopifyAPI::ScriptTag.stubs(:all).returns([stub(src: 'http://something-or-the-other.com/badscript.js', id: 7214109)])
    ShopifyAPI::ScriptTag.expects(:delete).never

    @manager.destroy_scripttags
  end

  private

  def expect_scripttag_creation(event, src)
    stub_scripttag = stub(persisted?: true)
    ShopifyAPI::ScriptTag.expects(:create).with(event: event, src: src, format: 'json').returns(stub_scripttag)
  end

  def all_scripttag_srcs
    @scripttags ||= ['https://example-app.com/fancy.js', 'https://example-app.com/foobar.js']
  end

  def all_mock_scripttags
    [
      stub(id: 1, src: "https://example-app.com/fancy.js", event: 'onload'),
      stub(id: 2, src: "https://example-app.com/foobar.js", event: 'onload'),
      
    ]
  end
end
