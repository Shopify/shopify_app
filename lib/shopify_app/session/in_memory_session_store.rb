# frozen_string_literal: true

module ShopifyApp
  class InMemorySessionStore
    class << self
      def store
        @store ||= {}
      end

      def retrieve(id)
        store[id]
      end

      def store_session(session, *_args)
        id = SecureRandom.uuid
        store[id] = session
        id
      end

      def clear
        @store = {}
      end

      private

      def repo
        Rails.logger.warn("[ShopifyApp::InMemorySessionStore] SessionStore is intended to be used in development / test only.")
        store
      end
    end
  end
end
