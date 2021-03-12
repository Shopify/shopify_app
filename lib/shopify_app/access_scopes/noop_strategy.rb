# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class NoopStrategy
      class << self
        def update_access_scopes?(*_args)
          false
        end
      end
    end
  end
end
