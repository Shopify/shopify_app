module ShopifyApp
  class SessionRepository
    class ConfigurationError < StandardError; end

    class << self
      def storage=(storage)
        @storage = storage

        unless storage.nil? || self.storage.respond_to?(:store) && self.storage.respond_to?(:retrieve)
          raise ArgumentError, "storage must respond to :store and :retrieve"
        end
      end

      def retrieve(id)
        storage.retrieve(id)
      end

      def retrieve_by_jwt(jwt)
        storage.retrieve_by_jwt(jwt)
      end

      def store(session, *args)
        storage.store(session, *args)
      end

      def storage
        load_storage || raise(ConfigurationError.new("ShopifySessionRepository.storage is not configured!"))
      end

      private

      def load_storage
        return unless @storage
        @storage.respond_to?(:safe_constantize) ? @storage.safe_constantize : @storage
      end
    end
  end
end
