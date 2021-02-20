# Shopify App

[![Version][gem]][gem_url] [![Build Status](https://github.com/Shopify/shopify_app/workflows/CI/badge.svg)](https://github.com/Shopify/shopify_app/actions?query=workflow%3ACI) ![Supported Rails version][supported_rails_version]

[gem]: https://img.shields.io/gem/v/shopify_app.svg
[gem_url]: https://rubygems.org/gems/shopify_app
[supported_rails_version]: https://img.shields.io/badge/rails-%3C6.1.0-orange

This gem builds Rails applications that can be embedded in the Shopify Admin.

[Introduction](#introduction) | 
[Requirements](#requirements) | 
[Usage](#usage) | 
[Documentation](#documentation) | 
[Contributing](/CONTRIBUTING.md) | 
[License](/LICENSE)

## Introduction

This gem includes a Rails engine, generators, modules, and mixins that help create Rails applications that work with Shopify APIs. The [Shopify App Rails engine](/docs/shopify_app/engine.md) provides all the code required to implement OAuth with Shopify. The [default Shopify App generator](#-environment-rails-generate-shopify_app) builds an app that can be embedded in the Shopify Admin and secures it with [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens).

<!-- This section is linked to in `templates/shopify_app.rb.tt`. Be careful renaming this heading. -->
## Requirements

> **Rails compatibility** 
> * Rails 6.1 or above is not yet supported due to the new `cookies_same_site_protection` setting. 
> * Use Shopify App `<= v7.2.8` if you need to work with Rails 4.

To become a Shopify app developer, you will need a [Shopify Partners](https://www.shopify.com/partners) account. Explore the official [Shopify docs](https://shopify.dev/concepts/shopify-introduction) to learn more about [*building Shopify apps*](https://shopify.dev/concepts/apps).

This gem requires that you have the following credentials:

- **Shopify API key:** The API key app credential specified in your [Shopify Partners dashboard](https://partners.shopify.com/organizations). 
- **Shopify API secret:** The API secret key app credential specified in your [Shopify Partners dashboard](https://partners.shopify.com/organizations). 

## Usage

1. To get started, create a new Rails app:

``` sh
$ rails new my_shopify_app
```

2. Add the Shopify App gem to `my_shopify_app`'s Gemfile.

```sh
$ bundle add shopify_app
```

3. Create a `.env` file in the root of `my_shopify_app` to specify your Shopify API credentials:

```
SHOPIFY_API_KEY=<Your Shopify API key>
SHOPIFY_API_SECRET=<Your Shopify API secret>
```

> In a development environment, you can use a gem like `dotenv-rails` to manage environment variables. 

4. Run the default Shopify App generator to create an app that can be embedded in the Shopify Admin:

```sh
$ rails generate shopify_app
```

5. Run a migration to create the necessary tables in your database:

```sh
$ rails db:migrate
```

6. Run the app:

```sh
$ rails server
```

See [*Quickstart*](/docs/Quickstart.md) to learn how to install your app on a shop.

This app implements [OAuth 2.0](https://shopify.dev/tutorials/authenticate-with-oauth) with Shopify to authenticate requests made to Shopify APIs. By default, this app is configured to use [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens) to authenticate merchants when embedded in the Shopify Admin.

See [*Generators*](#generators) for a complete list of generators available to Shopify App.

## Documentation

[Overview](#overview) | 
[Generators](#generators) | 
[Engine](#engine) | 
[API Versioning](#api-versioning)

### Overview

You can find documentation on gem usage, concepts, mixins, installation, and more in [`/docs`](/docs).

* Check out the [*Changelog*](/CHANGELOG.md) for notes on the latest gem releases.
* See [*Troubleshooting*](/docs/Troubleshooting.md) for tips on common issues.
* If you are looking to upgrade your Shopify App version to a new major release, see [*Upgrading*](/docs/Upgrading.md) for important notes on breaking changes.

### Generators

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

The [OAuth access scope(s)](https://shopify.dev/docs/admin-api/access-scopes) required by your app. Delimit multiple access scopes using a comma-space. The flag can be supplied with or without double-quotes.

*Example:* `--scope read_products, write_orders`

*Example:* `--scope "read_products, write_orders"`

###### `--embedded`

**[Not recommended]** Specify whether the app is an embedded app. Apps are embedded by default.

*Example:* `--embedded false`

###### `--with-cookie-authentication`

**[Not recommended]** Specify whether the app uses cookies to authenticate. By default, the app is configured to use [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens).

*Example:* `--with-cookie-authentication true`

---

#### `$ rails generate shopify_app:shop_model`

This generator creates a `Shop` model and a migration to store shop installation records. See [*Shop-based token strategy*](/docs/shopify_app/session-repository.md#shop-based-token-storage) to learn more.

---

#### `$ rails generate shopify_app:user_model`

This generator creates a `User` model and a migration to store user records. See [*User-based token strategy*](/docs/shopify_app/session-repository.md#user-based-token-storage) to learn more.

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

### Engine

Mounting the Shopify App Rails Engine provides the following routes. These routes are configured to help install your application on shops and implement OAuth.

| Verb   | Route                    | Action             |
|   ---: | :---                     | :---               |
| `GET`  | `/login`                 | Login              |
| `POST` | `/login`                 | Login              |
| `GET`  | `/auth/shopify/callback` | OAuth redirect URI |
| `GET`  | `/logout`                | Logout             |
| `POST` | `/webhooks/:type`        | Webhook callback   |

These routes are configurable. See [`/docs/shopify_app/engine.md`](/docs/shopify_app/engine.md) to learn how you can customize the login URL or mount the Shopify App Rails engine at nested routes.

To learn more about how this gem authenticates with Shopify, see [`/docs/shopify_app/authentication.md`](/docs/shopify_app/authentication.md).

### API Versioning

[Shopify's API is versioned](https://shopify.dev/concepts/about-apis/versioning). With Shopify App `v1.11.0`, the included Shopify API gem allows developers to specify and update the Shopify API version they want their app or service to use. The Shopify API gem also surfaces warnings to Rails apps about [deprecated endpoints, GraphQL fields and more](https://shopify.dev/concepts/about-apis/versioning#deprecation-practices).

See the [Shopify API gem README](https://github.com/Shopify/shopify_api/) for more information.
