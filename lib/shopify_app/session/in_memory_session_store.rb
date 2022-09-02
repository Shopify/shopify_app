# frozen_string_literal: true

module ShopifyApp
  # rubocop:disable Style/ClassVars
  # Class var repo is needed here in order to share data between the 2 child classes.
  class InMemorySessionStore
    def self.retrieve(id)
      repo[id]
    end

    def self.store(session, *_args)
      id = SecureRandom.uuid
      repo[id] = session
      id
    end

    def self.clear
      @@repo = nil
    end

    def self.repo
      if Rails.env.production?
        raise EnvironmentError, "Cannot use InMemorySessionStore in a Production environment. \
          Please initialize ShopifyApp with a model that can store and retrieve sessions"
      end
      @@repo ||= {}
    end
  end
  # rubocop:enable Style/ClassVars
end
