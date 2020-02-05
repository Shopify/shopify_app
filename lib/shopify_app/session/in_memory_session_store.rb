module ShopifyApp
  class InMemorySessionStore
    class EnvironmentError < StandardError; end

    def initialize
      repo
    end

    def retrieve(id)
      repo[id]
    end

    def store(session, *args)
      id = SecureRandom.uuid
      repo[id] = session
      id
    end

    def clear
      @repo = nil
    end

    def repo
      if Rails.env.production?
        raise EnvironmentError.new("Cannot use InMemorySessionStore in a Production environment. \
          Please initialize ShopifyApp with a model that can store and retrieve sessions")
      end
      @repo ||= {}
    end
  end
end
