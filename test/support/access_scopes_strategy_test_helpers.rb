# frozen_string_literal: true
module AccessScopesStrategyHelpers
  class MockUserScopesMatchStrategy
    class << self
      def scopes_mismatch_by_shopify_user_id?(*args)
        false
      end

      def scopes_mismatch_by_user_id?(*args)
        false
      end
    end
  end

  class MockUserScopesMismatchStrategy
    class << self
      def scopes_mismatch_by_shopify_user_id?(*args)
        true
      end

      def scopes_mismatch_by_user_id?(*args)
        true
      end
    end
  end


end
