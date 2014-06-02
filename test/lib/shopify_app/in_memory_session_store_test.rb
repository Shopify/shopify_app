require 'test_helper'

class InMemorySessionStoreTest < Minitest::Test
  def teardown
    InMemorySessionStore.clear
  end

  def test_storing_a_session
    uuid = InMemorySessionStore.store('something')
    assert_equal 'something', InMemorySessionStore.repo[uuid]
  end

  def test_finding_a_session
    InMemorySessionStore.repo['abra'] = 'something'
    assert_equal 'something', InMemorySessionStore.find('abra')
  end

  def test_clearing_the_store
    uuid = InMemorySessionStore.store('data')
    assert_equal 'data', InMemorySessionStore.find(uuid)
    InMemorySessionStore.clear
    assert !InMemorySessionStore.find(uuid), 'The sessions should have been removed'
  end
end
