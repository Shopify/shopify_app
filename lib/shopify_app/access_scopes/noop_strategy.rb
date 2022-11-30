# frozen_string_literal: true

module ShopifyApp
  module AccessScopes
    class NoopStrategy
      class << self
        def update_access_scopes?(*_args)
          false
        end

        def covered_scopes?(*_args)
          true
        end
      end
    end
  end
end
