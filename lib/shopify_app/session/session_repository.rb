# typed: true
module ShopifyApp
  class SessionRepository
    class ConfigurationError < StandardError; end

    class << self
      def shop_storage=(storage)
        @shop_storage = storage
      end

      def user_storage=(storage)
        @user_storage = storage
      end

      def retrieve_shop_session(id)
        shop_storage.retrieve(id)
      end

      def retrieve_user_session(id)
        user_storage.retrieve(id)
      end

      def store_shop_session(session)
        shop_storage.store(session)
      end

      def store_user_session(session, user)
        user_storage.store(session, user)
      end

      def shop_storage
        load_shop_storage || raise(ConfigurationError.new("ShopifySessionRepository.shop_storage is not configured!"))
      end

      def user_storage
        load_user_storage
      end

      private

      def load_shop_storage
        return unless @shop_storage
        @shop_storage.respond_to?(:safe_constantize) ? @shop_storage.safe_constantize : @shop_storage
      end

      def load_user_storage
        return unless @user_storage
        @user_storage.respond_to?(:safe_constantize) ? @user_storage.safe_constantize : @user_storage
      end
    end
  end
end
