require 'test_helper'

module ShopifyApp
  class InMemorySessionStoreTest < ActiveSupport::TestCase
    setup do
      @memory_store = ShopifyApp::InMemorySessionStore.new
    end

    teardown do
      @memory_store.clear
    end

    test "storing a session" do
      uuid = @memory_store.store('something')
      assert_equal 'something', @memory_store.repo[uuid]
    end

    test "retrieving a session" do
      @memory_store.repo['abra'] = 'something'
      assert_equal 'something', @memory_store.retrieve('abra')
    end

    test "clearing the store" do
      uuid = @memory_store.store('data')
      assert_equal 'data', @memory_store.retrieve(uuid)
      @memory_store.clear
      assert !@memory_store.retrieve(uuid), 'The sessions should have been removed'
    end

    test "it should raise when the environment is not valid" do
      Rails.env.stubs(:production?).returns(true)
      assert_raises InMemorySessionStore::EnvironmentError do
        @memory_store.store('data')
      end

      assert_raises InMemorySessionStore::EnvironmentError do
        @memory_store.retrieve('abracadabra')
      end
    end
  end
end
