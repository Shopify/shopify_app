# Controller Concerns

The following are controller concerns designed to be public controller concerns that can be included in your controllers. Concerns defined in `lib/shopify_app/controller_concerns` are designed to be private concerns and are not meant to be included directly into your controllers.

## Authenticated
Designed for controllers that are designed to handle authenticated actions by ensuring there is a valid session for the request.

In addition to session management, this concern will also handle localization, CSRF protection, embedded app settings, and billing enforcement.

#### Session Management
This concern will setup and teardown the session around the action. If the session cannot be setup for the requested shop the request will be redirected to login.

The concern will load sessions depending on your app's configuration:

**Embedded apps**

Cookies are not available for embedded apps because it loads in an iframe, so this concern will load the session from the request's `Authorization` header containing a session token, which can be set using [App Bridge](https://shopify.dev/apps/tools/app-bridge).

Learn more about [using `authenticatedFetch`](https://shopify.dev/apps/auth/oauth/session-tokens/getting-started#step-2-authenticate-your-requests) to create session tokens and authenticate your requests.

**Non-embedded apps**

Since cookies are available, the concern will load the session directly from them, so you can make regular `fetch` requests on your front-end.

#### Localization
I18n localization is saved to the session for consistent translations for the session.

#### CSRF Protection
Implements Rails' [protect_from_forgery](https://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html#method-i-protect_from_forgery) unless a valid session token is found for the request.

#### Embedded App
If your ShopifyApp configuration has the `embedded_app` config set to true, [P3P header](https://www.w3.org/P3P/) and [content security policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) are handled for you.

#### Billing Enforcement
If billing is enabled for the app, the active payment for the session is queried and enforced if needed. If billing is required the user will be redirected to a page requesting payment.

## EnsureAuthenticatedLinks
Designed to be more of a lightweight session concern specifically for XHR requests. Where `Authenticated` does far more than just session management, this concern will redirect to the splash page of the app if no active session was found.

## RequireKnownShop
Designed to handle unauthenticated requests. Rather than using the JWT to determine the requested shop of the request, the `shop` name is expected to be passed in the query string. If `shop` wasn't included in the query string params the request will be redirected to the login_url of the app.

If the shop session cannot be found for the provided `shop` in the query string, the requrest will be redirected to login or the `embedded_redirect_url`.

## ShopAccessScopesVerification
If scopes for the session don't match configuration of scopes defined in `config/initializers/shopify_app.rb` the user will be redirected to login or the `embedded_redirect_url`
