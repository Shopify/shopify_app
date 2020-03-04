module ShopifyApp
  class NullUserSessionStore
    class << self
      def retrieve(_)
        nil
      end

      def store(_, _)
        raise(SessionRepository::ConfigurationError.new('user_storage is not configured'))
      end

      def retrieve_by_jwt(_)
        nil
      end
    end
  end
end
