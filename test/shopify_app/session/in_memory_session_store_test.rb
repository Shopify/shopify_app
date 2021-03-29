# frozen_string_literal: true
require "test_helper"

module ShopifyApp
  class InMemorySessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemorySessionStore.clear
    end

    test "storing a session" do
      uuid = InMemorySessionStore.store("something")
      assert_equal "something", InMemorySessionStore.repo[uuid]
    end

    test "retrieving a session" do
      InMemorySessionStore.repo["abra"] = "something"
      assert_equal "something", InMemorySessionStore.retrieve("abra")
    end

    test "clearing the store" do
      uuid = InMemorySessionStore.store("data")
      assert_equal "data", InMemorySessionStore.retrieve(uuid)
      InMemorySessionStore.clear
      assert !InMemorySessionStore.retrieve(uuid), "The sessions should have been removed"
    end

    test "it should raise when the environment is not valid" do
      Rails.env.stubs(:production?).returns(true)
      assert_raises InMemorySessionStore::EnvironmentError do
        InMemorySessionStore.store("data")
      end

      assert_raises InMemorySessionStore::EnvironmentError do
        InMemorySessionStore.retrieve("abracadabra")
      end
    end
  end
end
