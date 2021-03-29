# frozen_string_literal: true
require "test_helper"

class ShopifyApp::ScripttagsManagerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @scripttags = [
      { event: "onload", src: "https://example-app.com/fancy.js" },
      { event: "onload", src: "https://example-app.com/foobar.js" },
      { event: "onload", src: ->(domain) { "https://example-app.com/#{domain}-123.js" } },
    ]

    @manager = ShopifyApp::ScripttagsManager.new(@scripttags, "example-app.com")
  end

  test "#create_scripttags makes calls to create scripttags" do
    ShopifyAPI::ScriptTag.stubs(all: [])

    expect_scripttag_creation("onload", "https://example-app.com/fancy.js")
    expect_scripttag_creation("onload", "https://example-app.com/foobar.js")
    expect_scripttag_creation("onload", "https://example-app.com/example-app.com-123.js")
    @manager.create_scripttags
  end

  test "#create_scripttags when creating a dynamic src, does not overwrite the src with its result" do
    ShopifyAPI::ScriptTag.stubs(all: [])

    stub_scripttag = stub(persisted?: true)
    ShopifyAPI::ScriptTag.expects(:create).returns(stub_scripttag).times(3)

    @manager.create_scripttags
    assert_respond_to @manager.required_scripttags.last[:src], :call
  end

  test "#create_scripttags when creating a scripttag fails, raises an error" do
    ShopifyAPI::ScriptTag.stubs(all: [])
    scripttag = stub(persisted?: false, errors: stub(full_messages: ["Source needs to be https"]))
    ShopifyAPI::ScriptTag.stubs(create: scripttag)

    e = assert_raise ShopifyApp::ScripttagsManager::CreationFailed do
      @manager.create_scripttags
    end

    assert_equal "Source needs to be https", e.message
  end

  test "#create_scripttags when a script src raises an exception, it's propagated" do
    ShopifyAPI::ScriptTag.stubs(:all).returns(all_mock_scripttags[0..1])
    @manager.required_scripttags.last[:src] = -> (_domain) { raise "oops!" }

    e = assert_raise do
      @manager.create_scripttags
    end

    assert_equal "oops!", e.message
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

  test "#destroy_scripttags makes calls to destroy scripttags with a dynamic src" do
    ShopifyAPI::ScriptTag.stubs(:all).returns(Array.wrap(all_mock_scripttags.last))
    ShopifyAPI::ScriptTag.expects(:delete).with(all_mock_scripttags.last.id)

    @manager.destroy_scripttags
  end

  test "#destroy_scripttags when deleting a dynamic src, does not overwrite the src with its result" do
    ShopifyAPI::ScriptTag.stubs(all: Array.wrap(all_mock_scripttags.last))
    ShopifyAPI::ScriptTag.expects(:delete).with(all_mock_scripttags.last.id)

    @manager.destroy_scripttags
    assert_respond_to @manager.required_scripttags.last[:src], :call
  end

  test "#destroy_scripttags does not destroy scripttags that do not have a matching address" do
    ShopifyAPI::ScriptTag.stubs(:all).returns([stub(src: "http://something-or-the-other.com/badscript.js",
                                                    id: 7214109)])
    ShopifyAPI::ScriptTag.expects(:delete).never

    @manager.destroy_scripttags
  end

  test ".queue enqueues a ScripttagsManagerJob" do
    args = {
      shop_domain: "example-app.com",
      shop_token: "token",
      scripttags: [event: "onload", src: "https://example-app.com/example-app.com-123.js"],
    }

    assert_enqueued_with(job: ShopifyApp::ScripttagsManagerJob, args: [args]) do
      ShopifyApp::ScripttagsManager.queue(args[:shop_domain], args[:shop_token], @scripttags[-1, 1])
    end
  end

  private

  def expect_scripttag_creation(event, src)
    stub_scripttag = stub(persisted?: true)
    ShopifyAPI::ScriptTag.expects(:create).with(event: event, src: src, format: "json").returns(stub_scripttag)
  end

  def all_mock_scripttags
    [
      stub(id: 1, src: "https://example-app.com/fancy.js", event: "onload"),
      stub(id: 2, src: "https://example-app.com/foobar.js", event: "onload"),
      stub(id: 3, src: "https://example-app.com/example-app.com-123.js", event: "onload"),
    ]
  end
end
