module ShopifyApp
  class SessionRepository
    class ConfigurationError < StandardError; end

    class << self
      def retrieve(id)
        ShopifyApp.configuration.session_repository.retrieve(id)
      end

      def store(session, *args)
        ShopifyApp.configuration.session_repository.store(session, *args)
      end
    end
  end
end
