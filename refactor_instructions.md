# Refactor Instructions: Remove Duplicate Validation Logic and Session Context Redundancy

## Overview
The current refactor contains duplicate implementations of functionality already provided by the `shopify_app_ai` gem. These instructions will guide you to remove redundant code while maintaining the public API.

## Phase 1: Remove Duplicate Auth Classes

### 1.1 Remove Custom AuthScopes Class
**File**: `lib/shopify_app/auth/auth_scopes.rb`

**Action**: Delete this file entirely.

**Replacement Strategy**:
- The `shopify_app_ai` package doesn't export AuthScopes, but we need to maintain the public API
- Keep a thin wrapper class that uses simple array operations for scope management
- Replace the current implementation with:

```ruby
# lib/shopify_app/auth/auth_scopes.rb
module ShopifyApp
  module Auth
    class AuthScopes
      attr_reader :scopes

      def initialize(scopes)
        @scopes = parse_scopes(scopes).uniq
      end

      def to_s
        @scopes.join(",")
      end

      def to_a
        @scopes.dup
      end

      def covers?(other)
        other_scopes = self.class.new(other).scopes
        (other_scopes - @scopes).empty?
      end

      def ==(other)
        self.class.new(other).scopes.sort == @scopes.sort
      end

      private

      def parse_scopes(scopes)
        case scopes
        when String
          scopes.split(/\s*,\s*/).map(&:strip).reject(&:empty?)
        when Array
          scopes.map(&:to_s).map(&:strip).reject(&:empty?)
        when AuthScopes
          scopes.scopes.dup
        else
          []
        end
      end
    end
  end
end
```

### 1.2 Remove Custom AssociatedUser Class
**File**: `lib/shopify_app/auth/associated_user.rb`

**Action**: Delete this file entirely.

**Replacement Strategy**:
- Use a simple OpenStruct or Hash for associated user data
- Update any code that creates AssociatedUser instances to use a hash instead

### 1.3 Simplify Session Class
**File**: `lib/shopify_app/auth/session.rb`

**Action**: Keep the class but simplify its implementation.

**Replacement Strategy**:
- Keep all public methods to maintain API compatibility
- Remove complex validation logic
- Use `shopify_app_ai` utilities where applicable

```ruby
# Key changes to make:
# 1. In the validate_jwt_token method, use shopify_app_ai's Utils:
def self.from_jwt_payload(shop:, payload:, access_token: nil, is_online: false)
  # Use shopify_app_ai's shop validation
  validated_shop = ::ShopifyApp::Utils.sanitize_shop_domain(shop)
  
  # Keep the rest of the method for API compatibility
  # ...
end
```

## Phase 2: Refactor SessionContext to Use shopify_app_ai Utilities

### 2.1 Update SessionContext Class
**File**: `lib/shopify_app/session_context.rb`

**Changes to make**:

1. **Replace shop validation logic**:
```ruby
# Instead of custom validation, use:
def self.validate_shop(shop)
  ::ShopifyApp::Utils.validate_shop_format(shop)
end
```

2. **Use shopify_app_ai utilities for configuration access**:
```ruby
# Update these methods to use shopify_app_ai patterns:
def self.api_key
  ShopifyApp.configuration.api_key
end

def self.api_secret_key
  ShopifyApp.configuration.secret
end
```

3. **Remove redundant host parsing**:
```ruby
# Simplify host-related methods by using shopify_app_ai utilities
def self.host
  ShopifyApp.configuration.host || ENV["HOST"] || raise("Host not configured")
end
```

## Phase 3: Update References

### 3.1 Update AccessScopes Strategy Classes
**Files**: 
- `lib/shopify_app/access_scopes/shop_strategy.rb`
- `lib/shopify_app/access_scopes/user_strategy.rb`

**Changes**:
- Ensure they work with the simplified AuthScopes class
- No changes needed if the public API of AuthScopes is maintained

### 3.2 Update Token Exchange
**File**: `lib/shopify_app/auth/token_exchange.rb`

**Changes**:
- In `build_session_from_response`, use a hash for associated_user instead of AssociatedUser class:

```ruby
def build_session_from_response(response_data, jwt_payload, online:)
  shop = jwt_payload["dest"]&.gsub(%r{^https://}, "")
  
  # Use shopify_app_ai's shop validation
  validated_shop = ::ShopifyApp::Utils.sanitize_shop_domain(shop)
  
  session = ShopifyApp::Auth::Session.from_access_token_response(
    shop: validated_shop,
    access_token_response: response_data.merge(
      "online_token" => online,
      "associated_user" => online ? {
        "id" => jwt_payload["sub"],
        "account_owner" => jwt_payload["account_owner"] || false,
      } : nil,
    ),
  )
  
  session
end
```

## Phase 4: Testing and Validation

### 4.1 Ensure All Tests Pass
- Run the full test suite
- Pay special attention to:
  - `test/shopify_app/auth/auth_scopes_test.rb`
  - `test/shopify_app/auth/session_test.rb`
  - `test/shopify_app/session_context_test.rb`

### 4.2 Verify Public API Compatibility
Ensure these public interfaces remain unchanged:
- `ShopifyApp::Auth::AuthScopes.new(scopes)`
- `ShopifyApp::Auth::Session` class and its public methods
- `ShopifyApp::SessionContext` class methods
- All methods used by `EnsureHasSession` concern

## Important Notes

1. **Maintain Backward Compatibility**: The public API must remain the same. Internal implementation can change, but public method signatures and behavior must be preserved.

2. **Use shopify_app_ai Utilities**: Wherever possible, replace custom implementations with calls to `::ShopifyApp::Utils` methods from shopify_app_ai:
   - `validate_shop_format`
   - `sanitize_shop_domain`
   - `validate_jwt_token`
   - `get_header_case_insensitive`
   - `validate_hmac_signature`

3. **Keep Thin Wrappers**: Where shopify_app_ai doesn't provide direct replacements, keep thin wrapper classes that maintain the expected API but with simplified implementations.

4. **Document Changes**: Add comments explaining why certain classes are kept as thin wrappers for API compatibility.

## Additional Simplifications

### Remove ShopifyAPI::Context Setup
**File**: `lib/generators/shopify_app/install/templates/shopify_app.rb.tt`

The initialization block that calls `ShopifyAPI::Context.setup` is no longer needed since we're using `shopify_app_ai` for authentication:

```ruby
Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    # ShopifyAPI context is now handled by ShopifyApp::SessionContext
    # No need to call ShopifyAPI::Context.setup anymore
    
    ShopifyApp::WebhooksManager.add_registrations
  end
end
```

### Simplify Error Handling
**File**: `lib/shopify_app/admin_api/with_token_refetch.rb`

Update error handling to use shopify_app_ai error types:

```ruby
rescue ShopifyApp::Errors::HttpResponseError => error
  if error.response[:status] != 401
    ShopifyApp::Logger.debug("Encountered error: #{error.response[:status]} - #{error.response.inspect}, re-raising")
  # ... rest of error handling
end
```

## Migration Checklist

- [ ] Back up the current implementation
- [ ] Replace AuthScopes with simplified version
- [ ] Remove AssociatedUser class
- [ ] Update Session class to use shopify_app_ai utilities
- [ ] Refactor SessionContext to leverage shopify_app_ai
- [ ] Update all references to removed/changed classes
- [ ] Run full test suite
- [ ] Test in a sample application
- [ ] Document any API changes in CHANGELOG
- [ ] Update README if necessary 