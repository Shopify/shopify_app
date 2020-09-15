# frozen_string_literal: true
module ShopifyApp
  class InMemoryActualSessionStore < InMemorySessionStore
    def self.store(session, session_id, user, *args)
      id = super
      repo[session_id.shopify_session_id] = session_id
      repo[session_id.shopify_user_id] = user
      id
    end

    def self.retrieve_by_shopify_session_id(session_id)
      repo[session_id]
    end
  end
end