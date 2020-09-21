# frozen_string_literal: true
module ShopifyApp
  class SessionRepository
    class ConfigurationError < StandardError; end

    class << self
      attr_writer :shop_storage

      attr_writer :user_storage

      attr_writer :actual_session_storage

      def retrieve_shop_session(id)
        shop_storage.retrieve(id)
      end

      def retrieve_user_session(id)
        user_storage.retrieve(id)
      end

      def retrieve_shop_session_by_shopify_domain(shopify_domain)
        shop_storage.retrieve_by_shopify_domain(shopify_domain)
      end

      def retrieve_user_session_by_shopify_user_id(user_id)
        user_storage.retrieve_by_shopify_user_id(user_id)
      end

      def retrieve_actual_session_by_shopify_session_id(session_id)
        actual_session_storage.retrieve_by_shopify_session_id(session_id)
      end 

      def store_shop_session(session)
        shop_storage.store(session)
      end

      def store_user_session(session, user)
        user_storage.store(session, user)
      end

      def store_actual_session(session, session_id, user, expires_at)
        actual_session_storage.store(session, session_id, user, expires_at)
      end

      def shop_storage
        load_shop_storage || raise(ConfigurationError, "ShopifySessionRepository.shop_storage is not configured!")
      end

      def user_storage
        load_user_storage
      end 

      def actual_session_storage
        load_actual_session_storage
      end

      def clean_up_actual_sessions
        actual_session_storage.clean_up
      end

      private

      def load_shop_storage
        return unless @shop_storage
        @shop_storage.respond_to?(:safe_constantize) ? @shop_storage.safe_constantize : @shop_storage
      end

      def load_user_storage
        return NullUserSessionStore unless @user_storage
        @user_storage.respond_to?(:safe_constantize) ? @user_storage.safe_constantize : @user_storage
      end

      def load_actual_session_storage
        return NullSessionStore unless @actual_session_storage
        @actual_session_storage.respond_to?(:safe_constantize) ? @actual_session_storage.safe_constantize : @actual_session_storage
      end
    end
  end
end
