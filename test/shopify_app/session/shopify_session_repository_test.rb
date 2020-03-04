require 'test_helper'

class TestSessionStore
  attr_reader :storage

  def initialize
    @storage = []
  end

  def retrieve(id)
    storage[id]
  end

  def store(session)
    id = storage.length
    storage[id] = session
    id
  end

  def retrieve_by_jwt(payload)
    retrieve(payload)
  end
end

class TestSessionStoreClass
  def self.store(session)
  end

  def self.retrieve(id)
  end

  def self.retrieve_by_jwt(_)
  end
end

class MockSessionStore < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end


class ShopifySessionRepositoryTest < ActiveSupport::TestCase
  attr_reader :session_store, :session

  setup do
    @session_store = TestSessionStore.new
    @session = ShopifyAPI::Session.new(
      domain: 'shop.myshopify.com',
      token: 'abracadabra',
      api_version: :unstable
    )
    ShopifyApp::SessionRepository.shop_storage = session_store
  end

  teardown do
    ShopifyApp::SessionRepository.shop_storage = nil
  end

  test "adding a session to the repository" do
    assert_equal 0, ShopifyApp::SessionRepository.store_shop_session(session)
    assert_equal session, session_store.retrieve(0)
  end

  test "retrieving a session from the repository" do
    session_store.storage[9] = session
    assert_equal session, ShopifyApp::SessionRepository.retrieve_shop_session(9)
  end

  test "retrieving a session for an id that does not exist" do
    ShopifyApp::SessionRepository.store_shop_session(session)
    assert !ShopifyApp::SessionRepository.retrieve_shop_session(100), "The session with id 100 should not exist in the Repository"
  end

  test "retrieving a session for a misconfigured shops repository" do
    ShopifyApp::SessionRepository.shop_storage = nil
    assert_raises ShopifyApp::SessionRepository::ConfigurationError do
      ShopifyApp::SessionRepository.retrieve_shop_session(0)
    end

    assert_raises ShopifyApp::SessionRepository::ConfigurationError do
      ShopifyApp::SessionRepository.store_shop_session(session)
    end
  end

  test "accepts a string and constantizes it" do
    ShopifyApp::SessionRepository.shop_storage = 'TestSessionStoreClass'
    assert_equal TestSessionStoreClass, ShopifyApp::SessionRepository.shop_storage
  end
end
