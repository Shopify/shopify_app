# WARNING - This really only works for development, see README for more details
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
        raise EnvironmentError.new("Cannot use InMemorySessionStore in a Production environment")
      end
      @@repo ||= {}
    end
  end
end
