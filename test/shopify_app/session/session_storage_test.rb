# frozen_string_literal: true

require 'test_helper'

class TestSessionStorage < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end

module ShopifyApp
  class SessionStorageTest < ActiveSupport::TestCase
    setup do
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migration.create_table(:test_session_storages) do |t|
        t.string(:shopify_domain)
        t.string(:shopify_token)
        t.string(:api_version)
      end

      @record = TestSessionStorage.new(
        shopify_domain: 'shop.myshopify.com',
        shopify_token: 'abracadabra',
        api_version: :unstable
      )
    end

    teardown do
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migration.drop_table(:test_session_storages)

      @record = nil
    end

    def validates_presence_of(field)
      @record.send("#{field}=", nil)
      @record.valid?

      assert_equal(@record.errors.details[field], [{ error: :blank }])
    end

    def validates_uniqueness_of(field)
      @record.save!

      duplicate = @record.dup
      duplicate.valid?

      assert_equal(duplicate.errors.details[:shopify_domain], [
        error: :taken,
        value: @record.send(field),
      ])
    end

    test 'validates presence of shopify_domain' do
      validates_presence_of(:shopify_domain)
    end

    test 'validates uniqueness of shopify_domain' do
      validates_uniqueness_of(:shopify_domain)
    end

    test 'validates presence of shopify_token' do
      validates_presence_of(:shopify_token)
    end

    test 'validates presence of api_version' do
      validates_presence_of(:api_version)
    end

    test 'downcases shopify_domain before validation' do
      @record.shopify_domain = 'SHOP.MYSHOPIFY.COM'
      @record.valid?

      assert_equal @record.shopify_domain, 'shop.myshopify.com'
    end
  end
end
