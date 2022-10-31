# Upgrading

This file documents important changes needed to upgrade your app's Shopify App version to a new major version.

#### Table of contents

[General Advice](#general-advice)

[Upgrading to `v20.2.0`](#upgrading-to-v2020)

[Upgrading to `v20.1.0`](#upgrading-to-v2010)

[Upgrading to `v19.0.0`](#upgrading-to-v1900)

[Upgrading to `v18.1.2`](#upgrading-to-v1812)

[Upgrading to `v17.2.0`](#upgrading-to-v1720)

[Upgrading to `v13.0.0`](#upgrading-to-v1300)

[Upgrading to `v11.7.0`](#upgrading-to-v1170)

[Upgrading from `v8.6` to `v9.0.0`](#upgrading-from-v86-to-v900)

## General Advice

Although we strive to make upgrades as smooth as possible, some effort may be required to stay up to date with the latest changes to `shopify_app`.

We strongly recommend you avoid 'monkeypatching' any existing code from `ShopifyApp`, e.g. by inheriting from `ShopifyApp` and then overriding particular methods. This can result in difficult upgrades. If your app does so, you will need to carefully check the gem's internal changes when upgrading.

If you need to upgrade by more than one major version (e.g. from v18 to v20), we recommend doing one at a time. Deploy each into production to help to detect problems earlier.

We also recommend the use of a staging site which matches your production environment as closely as possible.

If you do run into issues, we recommend looking at our [debugging tips.](https://github.com/Shopify/shopify_app/blob/main/docs/Troubleshooting.md#debugging-tips)

## Upgrading to `v20.2.0`

All custom errors defined inline within the `ShopifyApp` gem have been moved to `lib/shopify_app/errors.rb`.

- If you rescue any errors defined in this gem, you will need to rename them to match their new namespacing.

## Upgrading to `v20.1.0`

Note that the following steps are *optional* and only apply to **embedded** applications. However, they can improve the loading time of your embedded app at installation and re-auth.

- For embedded applications, update any controller that renders a full page reload (e.g: your home controller) to redirect using `Shopify::Auth.embedded_app_url`, if the `embedded` query argument is not present or does not equal `1`. Example [here](https://github.com/Shopify/shopify-app-template-ruby/pull/35/files#)
- If your app already has a frontend that uses App Bridge, this gem now supports using that to redirect out of the iframe before OAuth.  Example [here](https://github.com/Shopify/shopify-frontend-template-react/blob/main/pages/ExitIframe.jsx)
  - In your `shopify_app.rb` initializer, configure `.embedded_redirect_url` to the path of the route you added above.
  - If you don't set this route, then the `shopify_app` gem will automatically load its own copy of App Bridge and perform this redirection without any additional configuration.

## Upgrading to `v19.0.0`

*This change introduced a major change of strategy regarding sessions.*  Due to security changes with browsers, support for cookie based sessions was dropped. JWT is now the only supported method for managing sessions.

As part of that change, this update moves API authentication logic from this gem to the [`shopify_api`](https://github.com/Shopify/shopify-api-ruby) gem.

### High-level process

- Delete `config/initializers/omniauth.rb` as apps no longer need to initialize `OmniAuth` directly.
- Delete `config/initializers/user_agent.rb` as `shopify_app` will set the right `User-Agent` header for interacting
  with the Shopify API. If the app requires further information in the `User-Agent` header beyond what Shopify API
  requires, specify this in the `ShopifyAPI::Context.user_agent_prefix` setting.
- Remove `allow_jwt_authentication=` and `allow_cookie_authentication=` invocations from
  `config/initializers/shopify_app.rb` as the decision logic for which authentication method to use is now handled
  internally by the `shopify_api` gem, using the `ShopifyAPI::Context.embedded_app` setting.
- `v19.0.0` updates the `shopify_api` dependency to `10.0.0`. This version of `shopify_api` has breaking changes. See
  the documentation for addressing these breaking changes on GitHub [here](https://github.com/Shopify/shopify-api-ruby#breaking-change-notice-for-version-1000).

### Specific cases

#### Shopify user ID in session

Previously, we set the entire app user object in the `session` object.
As of v19, since we no longer save the app user to the session (but only the shopify user id), we now store it as `session[:shopify_user_id]`. Please make sure to update any references to that object.

#### Webhook Jobs

It is assumed that you have an ActiveJob implementation configured for `perform_later`, e.g. Sidekiq.
Ensure your jobs inherit from `ApplicationJob` or `ActiveJob::Base`.

Add a new `handle` method to existing webhook jobs to go through the updated `shopify_api` gem.

```ruby
class MyWebhookJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    # new handle function
    def handle(topic:, shop:, body:)
      # delegate to pre-existing perform_later function
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  # original perform function
  def perform(topic:, shop_domain:, webhook:)
    # ...
```

#### Temporary sessions

The new `shopify_api` gem offers a utility to temporarily create sessions for interacting with the API within a block.
This is useful for interacting with the Shopify API outside of the context of a subclass of `AuthenticatedController`.

```ruby
ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do |session|
  # make invocations to the API
end
```

Within a subclass of `AuthenticatedController`, the `current_shopify_session` function will return the current active
Shopify API session, or `nil` if no such session is available.

#### Setting up `ShopifyAPI::Context`

The `shopify_app` initializer must configure the `ShopifyAPI::Context`. The Rails generator will generate a block in the `shopify_app` initializer. To do so manually, you can refer to `after_initialize` block in the [template]((https://github.com/Shopify/shopify_app/blob/main/lib/generators/shopify_app/install/templates/shopify_app.rb.tt).

## Upgrading to `v18.1.2`

Version 18.1.2 replaces the deprecated EASDK redirect with an App Bridge 2 redirect when attempting to break out of an iframe. This happens when an app is installed, requires new access scopes, or re-authentication because the login session is expired.

## Upgrading to `v17.2.0`

### Different SameSite cookie attribute behavior

To support Rails `v6.1`, the [`SameSiteCookieMiddleware`](/lib/shopify_app/middleware/same_site_cookie_middleware.rb) was updated to configure cookies to `SameSite=None` if the app is embedded. Before this release, cookies were configured to `SameSite=None` only if this attribute had not previously been set before.

```diff
# same_site_cookie_middleware.rb
- cookie << '; SameSite=None' unless cookie =~ /;\s*samesite=/i
+ cookie << '; SameSite=None' if ShopifyApp.configuration.embedded_app?
```

By default, Rails `v6.1` configures `SameSite=Lax` on all cookies that don't specify this attribute.

## Upgrading to `v13.0.0`

Version 13.0.0 adds the ability to use both user and shop sessions, concurrently. This however involved a large
change to how session stores work. Here are the steps to migrate to 13.x

### Changes to `config/initializers/shopify_app.rb`

- _REMOVE_ `config.per_user_tokens = [true|false]` this is no longer needed
- _CHANGE_ `config.session_repository = 'Shop'` To `config.shop_session_repository = 'Shop'`
- _ADD (optional)_ User Session Storage `config.user_session_repository = 'User'`

### Shop Model Changes (normally `app/models/shop.rb`)

- _CHANGE_ `include ShopifyApp::SessionStorage` to `include ShopifyApp::ShopSessionStorage`

### Changes to the @shop_session instance variable (normally in `app/controllers/*.rb`)

- _CHANGE_ if you are using shop sessions, `@shop_session` will need to be changed to `@current_shopify_session`.

### Changes to Rails `session`

- _CHANGE_ `session[:shopify]` is no longer set. Use `session[:user_id]` if your app uses user based tokens, or `session[:shop_id]` if your app uses shop based tokens.

### Changes to `ShopifyApp::LoginProtection`

`ShopifyApp::LoginProtection`

- CHANGE if you are using `ShopifyApp::LoginProtection#shopify_session` in your code, it will need to be
  changed to `ShopifyApp::LoginProtection#activate_shopify_session`
- CHANGE if you are using `ShopifyApp::LoginProtection#clear_shop_session` in your code, it will need to be
  changed to `ShopifyApp::LoginProtection#clear_shopify_session`

### Notes

You do not need a user model; a shop session is fine for most applications.

---

## Upgrading to `v11.7.0`

### Session storage method signature breaking change

If you override `def self.store(auth_session)` method in your session storage model (e.g. Shop), the method signature has changed to `def self.store(auth_session, *args)` in order to support user-based token storage. Please update your method signature to include the second argument.

---

## Upgrading from `v8.6` to `v9.0.0`

### Configuration change

Add an API version configuration in `config/initializers/shopify_app.rb`
Set this to the version you want to run against by default. See [Shopify API docs](https://help.shopify.com/api/versioning) for versions available.

```ruby
config.api_version = '2019-04'
```

### Session storage change

You will need to add an `api_version` method to your session storage object. The default implementation for this is.

```ruby
def api_version
  ShopifyApp.configuration.api_version
end
```

### Generated file change

`embedded_app.html.erb` the usage of `shop_session.url` needs to be changed to `shop_session.domain`

```erb
<script type="text/javascript">
  ShopifyApp.init({
    apiKey: "<%= ShopifyApp.configuration.api_key %>",

    shopOrigin: "<%= "https://#{ @shop_session.url }" if @shop_session %>",

    debug: false,
    forceRedirect: true
  });
</script>
```

is changed to

```erb
<script type="text/javascript">
  ShopifyApp.init({
    apiKey: "<%= ShopifyApp.configuration.api_key %>",

    shopOrigin: "<%= "https://#{ @shop_session.domain }" if @shop_session %>",

    debug: false,
    forceRedirect: true
  });
</script>
```

### ShopifyAPI changes

You will need to also follow the ShopifyAPI [upgrade guide](https://github.com/Shopify/shopify-api-ruby/blob/master/README.md#-breaking-change-notice-for-version-700-) to ensure your app is ready to work with API versioning.

[dashboard]: https://partners.shopify.com
[app-bridge]: https://shopify.dev/apps/tools/app-bridge
