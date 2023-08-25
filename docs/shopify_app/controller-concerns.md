# Controller Concerns

The following controller concerns are designed to be public and can be included in your controllers.

If you are looking to make requests within the context of a logged in **User**, you will include `EnsureHasSession` into your controller to ensure users have a valid session to make requests.


```ruby
class YourController < ApplicationController
  include ShopifyApp::EnsureHasSession
end
```

If you don't require a user to be present but make requests scoped by a **Shop**, you can include `EnsureInstalled` in your controller to ensure your app has been installed by the Shop and they have a shop session.

```ruby
class YourController < ApplicationController
  include ShopifyApp::EnsureInstalled
end
```

## EnsureHasSession - Online User Sessions
Designed for controllers that are designed to handle authenticated actions by ensuring there is a valid session for the request.

In addition to session management, this concern will also handle localization, CSRF protection, embedded app settings, and billing enforcement.

## EnsureInstalled - Offline Shop Sessions
Designed to handle request scoped by a shop for *embedded apps*. If you are non-embedded app, we recommend using `EnsureHasSession` concern instead of this one.

Rather than using the JWT to determine the requested shop of the request, the `shop` name param is taken from the query string that Shopify Admin provides.

If the shop session cannot be found for the provided `shop` in the query string, the request will be redirected to login or the `embedded_redirect_url`.

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

#### EnsureBilling
If billing is enabled for the app, the active payment for the session is queried and enforced if needed. If billing is required the user will be redirected to a page requesting payment.
