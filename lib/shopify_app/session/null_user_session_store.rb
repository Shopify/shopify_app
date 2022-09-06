# frozen_string_literal: true

module ShopifyApp
  class NullUserSessionStore
    class << self
      def retrieve(_)
        nil
      end

      def store(_, _)
        raise ::ShopifyApp::Errors::ConfigurationError, "user_storage is not configured"
      end

      def retrieve_by_shopify_user_id(_)
        nil
      end

      def blank?
        true
      end
    end
  end
end
