# Upgrading 

This file documents important changes needed to upgrade your app's Shopify App version to a new major version.

#### Table of contents

[Upgrading to `v19.0.0`](#upgrading-to-v1900)

[Upgrading to `v17.2.0`](#upgrading-to-v1720)

[Upgrading to `v13.0.0`](#upgrading-to-v1300)

[Upgrading to `v11.7.0`](#upgrading-to-v1170)

[Upgrading from `v8.6` to `v9.0.0`](#upgrading-from-v86-to-v900)

## Upgrading to `v19.0.0`

This update moves API authentication logic from this gem to the [`shopify_api`](https://github.com/Shopify/shopify_api)
gem.

### High-level process

* Delete `config/initializers/omniauth.rb` as apps no longer need to initialize `OmniAuth` directly.
* Delete `config/initializers/user_agent.rb` as `shopify_app` will set the right `User-Agent` header for interacting
  with the Shopify API. If the app requires further information in the `User-Agent` header beyond what Shopify API
  requires, specify this in the `ShopifyAPI::Context.user_agent_prefix` setting.
* Remove `allow_jwt_authentication=` and `allow_cookie_authentication=` invocations from
  `config/initializers/shopify_app.rb` as the decision logic for which authentication method to use is now handled
  internally by the `shopify_api` gem.
* `v19.0.0` updates the `shopify_api` dependency to `10.0.0`. This version of `shopify_api` has breaking changes. See
  the documentation for addressing these breaking changes on GitHub [here](https://github.com/Shopify/shopify_api/blob/add_breaking_change_log_v10/README.md#breaking-change-notice-for-version-1000).

### Specific cases

#### Webhook Jobs

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

The new `shopify_api` gem offers a utility to temporarily create sessions for interacting with the API within a block. This is useful for interacting with the Shopify API outside of the context of
a subclass of `AuthenticatedController`.

```ruby
ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do |session|
  # make invocations to the API
end
```

#### Setting up `ShopifyAPI::Context`

The `shopify_app` initializer must configure the `ShopifyAPI::Context`. The Rails generator will
generate a block in the `shopify_app` initializer. To do so manually, ensure the following is
part of the `after_initialize` block in `shopify_app.rb`.

```ruby
Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      api_version: ShopifyApp.configuration.api_version,
      host_name: URI(ENV.fetch('HOST', '')).host || '',
      scope: ShopifyApp.configuration.scope,
      is_private: !ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', '').empty?,
      is_embedded: ShopifyApp.configuration.embedded_app,
      session_storage: ShopifyApp::SessionRepository,
      logger: Rails.logger,
      private_shop: ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', nil),
      user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
    )

    ShopifyApp::WebhooksManager.add_registrations
  end
end
```

## Upgrading to `v17.2.0`

### Different SameSite cookie attribute behaviour

To support Rails  `v6.1`, the [`SameSiteCookieMiddleware`](/lib/shopify_app/middleware/same_site_cookie_middleware.rb) was updated to configure cookies to `SameSite=None` if the app is embedded. Before this release, cookies were configured to `SameSite=None` only if this attribute had not previously been set before.

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

- *REMOVE* `config.per_user_tokens = [true|false]` this is no longer needed
- *CHANGE* `config.session_repository = 'Shop'` To  `config.shop_session_repository = 'Shop'`
- *ADD (optional)*  User Session Storage `config.user_session_repository = 'User'`

### Shop Model Changes (normally `app/models/shop.rb`)

-  *CHANGE* `include ShopifyApp::SessionStorage` to `include ShopifyApp::ShopSessionStorage`

### Changes to the @shop_session instance variable (normally in `app/controllers/*.rb`)

- *CHANGE* if you are using shop sessions, `@shop_session` will need to be changed to `@current_shopify_session`.

### Changes to Rails `session`

- *CHANGE* `session[:shopify]` is no longer set. Use `session[:user_id]` if your app uses user based tokens, or `session[:shop_id]` if your app uses shop based tokens.

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
Set this to the version you want to run against by default. See [Shopify API docs](https://help.shopify.com/en/api/versioning) for versions available.
```ruby
config.api_version = '2019-04'
```

### Session storage change

You will need to add an `api_version` method to your session storage object.  The default implementation for this is.
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

You will need to also follow the ShopifyAPI [upgrade guide](https://github.com/Shopify/shopify_api/blob/master/README.md#-breaking-change-notice-for-version-700-) to ensure your app is ready to work with API versioning.

[dashboard]:https://partners.shopify.com
[app-bridge]:https://help.shopify.com/en/api/embedded-apps/app-bridge