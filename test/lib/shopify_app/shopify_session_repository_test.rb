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
end

class TestSessionStoreClass
  def self.store(session)
  end

  def self.retrieve(id)
  end
end

class ShopifySessionRepositoryTest < Minitest::Test
  attr_reader :session_store, :session
  def setup
    @session_store = TestSessionStore.new
    @session = ShopifyAPI::Session.new('shop.myshopify.com', 'abracadabra')
    ShopifySessionRepository.storage = session_store
  end

  def teardown
    ShopifySessionRepository.storage = nil
  end

  def test_adding_a_session_to_the_repository
    assert_equal 0, ShopifySessionRepository.store(session)
    assert_equal session, session_store.retrieve(0)
  end

  def test_retrieving_a_session_from_the_repository
    session_store.storage[9] = session
    assert_equal session, ShopifySessionRepository.retrieve(9)
  end

  def test_retrieving_a_session_for_an_id_that_does_not_exist
    ShopifySessionRepository.store(session)
    assert !ShopifySessionRepository.retrieve(100), "The session with id 100 should not exist in the Repository"
  end

  def test_retrieving_a_session_for_a_misconfigured_shops_repository
    ShopifySessionRepository.storage = nil
    assert_raises ShopifySessionRepository::ConfigurationError do
      ShopifySessionRepository.retrieve(0)
    end

    assert_raises ShopifySessionRepository::ConfigurationError do
      ShopifySessionRepository.store(session)
    end
  end

  def test_accepts_a_string_and_constantizes_it
    ShopifySessionRepository.storage = 'TestSessionStoreClass'
    assert_equal TestSessionStoreClass, ShopifySessionRepository.storage
  end
end
