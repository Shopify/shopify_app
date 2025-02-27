# Generators

> Listed below are the generators currently offered by the Shopify App gem. To learn more about how this gem creates an embedded app, start with the [default Shopify App generator](#-environment-rails-generate-shopify_app).

---

#### `$ [environment] rails generate shopify_app`

The default generator will run the [`install`](#-rails-generate-shopify_appinstall-flags), [`shop_model`](#-rails-generate-shopify_appshop_model), [`authenticated_controller`](#-rails-generate-shopify_appauthenticated_controller), and [`home_controller`](#-rails-generate-shopify_apphome_controller-flags) generators. This is the recommended way to start a new app from scratch.

##### Environment

###### `SHOPIFY_APP_DISABLE_WEBPACKER`

**[Optional]** Specify this environment variable if your app uses sprockets with Rails 6 or to generate a Shopify App without webpacker.

*Example:*

Run:

```terminal
$ SHOPIFY_APP_DISABLE_WEBPACKER=1 rails generate shopify_app
```

Add the following code to your ShopifyApp configuration block:

```ruby
ShopifyApp.configure do |config|
  config.disable_webpacker = true
end
```

---

#### `$ rails generate shopify_app:install [flags]`

This generator adds ShopifyApp and the required initializers to the host Rails application. You can update any of these settings later.

##### Flags

###### `--application_name`

The name of your app. The flag can be supplied with or without double-quotes.

*Example:* `--application_name "My Shopify App"`

###### `--scope`

The [OAuth access scope(s)](https://shopify.dev/docs/api/usage/access-scopes) required by your app. Delimit multiple access scopes using a comma-space. The flag can be supplied with or without double-quotes.

*Example:* `--scope read_products, write_orders`

*Example:* `--scope "read_products, write_orders"`

###### `--embedded`

Specify whether the app is an embedded app. Apps are embedded by default.

*Example:* `--embedded false`

###### `--with-cookie-authentication`

**[Not recommended]** Specify whether the app uses cookies to authenticate. By default, the app is configured to use [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens).

*Example:* `--with-cookie-authentication true`

---

#### `$ rails generate shopify_app:shop_model`

This generator creates a `Shop` model and a migration to store shop installation records. See [*Shop-based token strategy*](/docs/shopify_app/sessions.md#shop-offline-token-storage) to learn more.

---

#### `$ rails generate shopify_app:user_model`

This generator creates a `User` model and a migration to store user records. See [*User-based token strategy*](/docs/shopify_app/sessions.md#user-online-token-storage) to learn more.

---

#### `$ rails generate shopify_app:authenticated_controller`

This generator creates a sample authenticated controller. By default, inheriting from this controller protects your app controllers using session tokens. See [*Authentication*](/docs/shopify_app/authentication.md) to learn more.

---

#### `$ rails generate shopify_app:home_controller [flags]`

This generator creates a sample home controller with a view that displays a shop's products. This generator also runs the [`products_controller`](#-rails-generate-shopify_appproducts_controller) generator.

##### Flags

###### `--with-cookie-authentication`

**[Not recommended]**  This flag generates an authenticated home controller. Use this flag only if your app uses cookies to authenticate. By default, the home controller is unauthenticated.

---

#### `$ rails generate shopify_app:products_controller`

This generator creates a sample products API controller to fetch products using the Shopify REST API.

---

#### `$ rails generate shopify_app:add_after_authenticate_job`

**[Optional]** This generator creates a skeleton job that runs after the OAuth authorization flow. See [*Run jobs after the OAuth flow*](/docs/shopify_app/authentication.md#run-jobs-after-the-oauth-flow) for more information.

---

#### `$ rails generate shopify_app:app_proxy_controller`

**[Optional]** This generator creates the app proxy controller to handle proxy requests to the app from your shop storefront. It also modifies 'config/routes.rb' with a namespace route and creates a sample view that displays current shop information using the LiquidAPI. See [*Verify HTTP requests sent via an app proxy*](/docs/shopify_app/engine.md#verify-http-requests-sent-via-an-app-proxy) for more information.

---

#### `$ rails generate shopify_app:marketing_activity_extension`

**[Optional]** This generator creates a controller with the endpoints required to build a [marketing activities extension](https://shopify.dev/docs/marketing-activities). The extension is generated with the base URL `/marketing_activities`. This URL would need to be configured in the Shopify Partners dashboard.

---

#### `$ rails generate shopify_app:controllers`

**[Optional]** This generator is for your convenience. Run this generator if you would like to override code that is part of the Shopify App Rails engine.

*Example:* The Shopify App Rails engine provides a sample [`SessionsController`](/app/controllers/shopify_app/sessions_controller.rb). Running this generator copies this controller to your app so you can begin extending it. Routes and views follow the same pattern.
