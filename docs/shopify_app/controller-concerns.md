# Controller Concerns

The following controller concerns are designed to be public and can be included in your controllers.

For any controller that makes Shopify API calls, accesses shop data, or performs authenticated actions, use `EnsureHasSession`. This concern verifies the identity of the requester before allowing the action to proceed.

```ruby
class YourController < ApplicationController
  include ShopifyApp::EnsureHasSession
end
```

If you only need to check whether the app is installed on a shop — for example, to serve your app's frontend shell — use `EnsureInstalled`. This concern does not authenticate the request.

```ruby
class YourController < ApplicationController
  include ShopifyApp::EnsureInstalled
end
```

## EnsureHasSession — Authenticated Requests
Use this concern for any controller action that needs to make authenticated Shopify API calls or access shop/user data. It verifies the requester's identity using either session tokens (embedded apps) or encrypted cookies (non-embedded apps), and works with both online (user) and offline (shop) access tokens.

In addition to session management, this concern handles localization, CSRF protection, embedded app settings, and billing enforcement.

## EnsureInstalled — Installation Check Only
Use this concern to verify that the app has been installed on a given shop. It is designed for unauthenticated entry points in embedded apps, such as serving the app shell or redirecting to OAuth.

> ⚠️ **This concern does not authenticate the request.** The shop is resolved from the `shop` query string parameter, which is user-controllable. Do not use this concern to gate access to shop data, access tokens, or Shopify API calls. For authenticated actions, use `EnsureHasSession`.

If the app is not installed for the provided `shop` parameter, the request will be redirected to login or the `embedded_redirect_url`.

## EnsureAuthenticatedLinks
Designed to be more of a lightweight session concern specifically for XHR requests. Where `EnsureHasSession` does far more than just session management, this concern will redirect to the splash page of the app if no active session was found.

## ShopAccessScopesVerification
If scopes for the session don't match configuration of scopes defined in `config/initializers/shopify_app.rb` the user will be redirected to login or the `embedded_redirect_url`.

# Private Concerns used with EnsureHasSession
These concerns shouldn't be included directly, but we provide some documentation as to their functionality that are included with `EnsureHasSession`. Concerns defined in `lib/shopify_app/controller_concerns` are designed to be private and are not meant to be included directly into your controllers.

#### LoginProtection - Session Management
This concern will setup and teardown the session around the action. If the session cannot be setup for the requested shop the request will be redirected to login.

The concern will load sessions depending on your app's configuration:

**Embedded apps**

Cookies are not available for embedded apps because it loads in an iframe, so this concern will load the session from the request's `Authorization` header containing a session token, which can be set using [App Bridge](https://shopify.dev/apps/tools/app-bridge).

Learn more about [using `authenticatedFetch`](https://shopify.dev/apps/auth/oauth/session-tokens/getting-started#step-2-authenticate-your-requests) to create session tokens and authenticate your requests.

**Non-embedded apps**

Since cookies are available, the concern will load the session directly from them, so you can make regular `fetch` requests on your front-end.

#### Localization
I18n localization is saved to the session for consistent translations for the session.

#### CSRFProtection
Implements Rails' [protect_from_forgery](https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html#method-i-protect_from_forgery) unless a valid session token is found for the request.

#### EmbeddedApp
If your ShopifyApp configuration has the `embedded_app` config set to true, [P3P header](https://www.w3.org/P3P/) and [content security policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) are handled for you.

##### Content Security Policy (CSP) Directives:

The EmbeddedApp concern automatically configures the following CSP directives to ensure your embedded app works correctly within Shopify Admin:

1. **frame-ancestors**: Allows the app to be embedded in iframes from:
   - The current shop domain (e.g., `https://example.myshopify.com`)
   - Shopify's unified admin domain (e.g., `https://admin.shopify.com`)

2. **script-src**: Allows JavaScript execution from:
   - `'self'` - Scripts from your app's own domain
   - `https://cdn.shopify.com/shopifycloud/app-bridge.js` - Required for App Bridge functionality
   - Any other script sources you explicitly add in your controller

These CSP settings ensure that:
- Your app can be properly embedded within Shopify Admin
- App Bridge can load and function correctly
- Your app maintains security while allowing necessary Shopify integrations

##### Layout

By default, the `EmbeddedApp` concern also sets the layout file to be `app/views/layouts/embedded_app.html.erb`.

Sometimes one wants to run an embedded app in non-embedded mode. For example:

- When the remote environment is a CI;
- When the remote environment is a preview/PR app;
- When the developer wants to run the app in a non-embedded mode for testing.

To use the same application layout for every application controller, a developer can now overwrite the `#use_embedded_app_layout?` method.

```ruby
class ApplicationController
  # Ensures every controller is using the standard app/views/layouts/application.html.erb layout.
  #
  # @return [true, false]
  def use_embedded_app_layout?
    false
  end
end
```

#### EnsureBilling
If billing is enabled for the app, the active payment for the session is queried and enforced if needed. If billing is required the user will be redirected to a page requesting payment.
