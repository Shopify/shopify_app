module ShopifyApp
  class InMemorySessionStore
    class EnvironmentError < StandardError; end

    def self.retrieve(id)
      repo[id]
    end

    def self.store(session)
      id = SecureRandom.uuid
      repo[id] = session
      id
    end

    def self.clear
      @@repo = nil
    end

    def self.repo
      if Rails.env.production?
        raise EnvironmentError.new("Cannot use InMemorySessionStore in a Production environment. \
          Please initialize ShopifyApp with a model that can store and retrieve sessions")
      end
      @@repo ||= {}
    end
  end
end
