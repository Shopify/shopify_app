# Upgrading 

This file documents important changes needed to upgrade your app's Shopify App version to a new major version.

#### Table of contents

[Upgrading to `v13.0.0`](#upgrading-to-v1300)

[Upgrading to `v11.7.0`](#upgrading-to-v1170)

[Upgrading from `v8.6` to `v9.0.0`](#upgrading-from-v86-to-v900)

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