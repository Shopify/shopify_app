# frozen_string_literal: true
module ShopifyApp
  class NullSessionStore
    class << self
      def retrieve(_)
        nil
      end

      def store(_, _, _)
        raise SessionRepository::ConfigurationError, 'session_storage is not configured'
      end

      def retrieve_by_shopify_session_id(_)
        nil
      end

      def blank?
        true
      end
    end
  end
end
