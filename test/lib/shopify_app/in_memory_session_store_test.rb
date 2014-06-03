require 'test_helper'

class InMemorySessionStoreTest < Minitest::Test
  def teardown
    InMemorySessionStore.clear
  end

  def test_storing_a_session
    uuid = InMemorySessionStore.store('something')
    assert_equal 'something', InMemorySessionStore.repo[uuid]
  end

  def test_retrieving_a_session
    InMemorySessionStore.repo['abra'] = 'something'
    assert_equal 'something', InMemorySessionStore.retrieve('abra')
  end

  def test_clearing_the_store
    uuid = InMemorySessionStore.store('data')
    assert_equal 'data', InMemorySessionStore.retrieve(uuid)
    InMemorySessionStore.clear
    assert !InMemorySessionStore.retrieve(uuid), 'The sessions should have been removed'
  end

  def test_it_should_raise_when_the_environment_is_not_valid
    Rails.env.stubs(:production?).returns(true)
    assert_raises InMemorySessionStore::EnvironmentError do
      InMemorySessionStore.store('data')
    end

    assert_raises InMemorySessionStore::EnvironmentError do
      InMemorySessionStore.retrieve('abracadabra')
    end
  end
end
