module ShopifyApp
  class SessionRepository
    class ConfigurationError < StandardError; end

    EXPECTED_METHODS = [:store, :retrieve, :retrieve_by_jwt].freeze

    class << self
      def shop_storage=(storage)
        @shop_storage = load_shop_storage(storage)
        return unless storage

        raise ArgumentError, "shop storage does not have expected interface" unless expected_interface?(shop_storage)
      end

      def user_storage=(storage)
        @user_storage = load_user_storage(storage)
        return unless storage

        raise ArgumentError, "user storage does not have expected interface" unless expected_interface?(user_storage)
      end

      def retrieve_shop_session(id)
        shop_storage.retrieve(id)
      end

      def retrieve_user_session(id)
        user_storage.retrieve(id)
      end

      def retrieve_shop_session_by_jwt(payload)
        shop_storage.retrieve_by_jwt(payload)
      end

      def retrieve_user_session_by_jwt(payload)
        user_storage.retrieve_by_jwt(payload)
      end

      def store_shop_session(session)
        shop_storage.store(session)
      end

      def store_user_session(session, user)
        user_storage.store(session, user)
      end

      def shop_storage
        @shop_storage
      end

      def user_storage
        @user_storage
      end

      private

      def load_shop_storage(storage)
        return NullShopSessionStore unless storage
        storage.respond_to?(:safe_constantize) ? storage.safe_constantize : storage
      end

      def load_user_storage(storage)
        return NullUserSessionStore unless storage
        storage.respond_to?(:safe_constantize) ? storage.safe_constantize : storage
      end

      def expected_interface?(storage)
        EXPECTED_METHODS.all? { |method| storage.respond_to?(method) }
      end
    end
  end
end
