module ShopifyApp
  class NullShopSessionStore
    class << self
      def retrieve(_)
        raise_configuration_error
      end

      def store(_, _)
        raise_configuration_error
      end

      def retrieve_by_jwt(_)
        raise_configuration_error
      end

      def blank?
        true
      end

      private

      def raise_configuration_error
        raise(SessionRepository::ConfigurationError.new('user_storage is not configured'))
      end
    end
  end
end
