# Shopify App

[![Version][gem]][gem_url] [![Build Status](https://github.com/Shopify/shopify_app/workflows/CI/badge.svg)](https://github.com/Shopify/shopify_app/actions?query=workflow%3ACI)

[gem]: https://img.shields.io/gem/v/shopify_app.svg
[gem_url]: https://rubygems.org/gems/shopify_app

This gem builds Rails applications that can be embedded in the Shopify Admin.

[Introduction](#introduction) |
[Requirements](#requirements) |
[Usage](#usage) |
[Documentation](#documentation) |
[Contributing](/CONTRIBUTING.md) |
[License](/LICENSE)


## Introduction

This gem includes a Rails engine, generators, modules, and mixins that help create Rails applications that work with Shopify APIs. The [Shopify App Rails engine](/docs/shopify_app/engine.md) provides all the code required to implement OAuth with Shopify. The [default Shopify App generator](/docs/shopify_app/generators.md#-environment-rails-generate-shopify_app) builds an app that can be embedded in the Shopify Admin and secures it with [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens).

<!-- This section is linked to in `templates/shopify_app.rb.tt`. Be careful renaming this heading. -->
## Requirements

To become a Shopify app developer, you will need a [Shopify Partners](https://www.shopify.com/partners) account. Explore the [Shopify dev docs](https://shopify.dev/concepts/shopify-introduction) to learn more about [building Shopify apps](https://shopify.dev/concepts/apps).

This gem requires that you have the following credentials:

- **Shopify API key:** The API key app credential specified in your [Shopify Partners dashboard](https://partners.shopify.com/organizations).
- **Shopify API secret:** The API secret key app credential specified in your [Shopify Partners dashboard](https://partners.shopify.com/organizations).

## Usage

1. To get started, create a new Rails app:

``` sh
rails new my_shopify_app
```

2. Add the Shopify App gem to the app's Gemfile:

```sh
bundle add shopify_app
```

3. You will need to provide several environment variables to the app.
There are a variety of way of doing this, but for a development environment we recommended the [`dotenv-rails`](https://github.com/bkeepers/dotenv) gem.
Create a `.env` file in the root of your Rails app to specify the full host and Shopify API credentials:

```sh
HOST=http://localhost:3000
SHOPIFY_API_KEY=<Your Shopify API key>
SHOPIFY_API_SECRET=<Your Shopify API secret>
```

4. Run the default Shopify App generator to create an app that can be embedded in the Shopify Admin:

```sh
rails generate shopify_app
```

5. Run a migration to create the necessary tables in your database:

```sh
rails db:migrate
```

6. Run the app:

```sh
rails server
```

7. Within [Shopify Partners](https://www.shopify.com/partners), navigate to your App, then App Setup, and configure the URLs, e.g.:

  * App URL: http://127.0.0.1:3000/
  * Allowed redirection URL(s): http://127.0.0.1:3000/auth/shopify/callback

8. Install the app by visiting the server's URL (e.g. http://127.0.0.1:3000) and specifying the subdomain of the shop where you want it to be installed to.

9. After the app is installed, you're redirected to the embedded app.

This app implements [OAuth 2.0](https://shopify.dev/tutorials/authenticate-with-oauth) with Shopify to authenticate requests made to Shopify APIs. By default, this app is configured to use [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens) to authenticate merchants when embedded in the Shopify Admin.

See [*Generators*](/docs/shopify_app/generators.md) for a complete list of generators available to Shopify App.

## Documentation

You can find documentation on gem usage, concepts, mixins, installation, and more in [`/docs`](/docs).

* Start with the [*Generators*](/docs/shopify_app/generators.md) document to learn more about the generators this gem offers.
* Check out the [*Changelog*](/CHANGELOG.md) for notes on the latest gem releases.
* See [*Troubleshooting*](/docs/Troubleshooting.md) for tips on common issues.
* If you are looking to upgrade your Shopify App version to a new major release, see [*Upgrading*](/docs/Upgrading.md) for important notes on breaking changes.

### Overview

[Quickstart](/docs/Quickstart.md)

[Troubleshooting](/docs/Troubleshooting.md)

[Upgrading](/docs/Upgrading.md)

[Shopify App](/docs/shopify_app)
  * [Authentication](/docs/shopify_app/authentication.md)
  * [Engine](/docs/shopify_app/engine.md)
  * [Controller Concerns](/docs/shopify_app/controller-concerns.md)
  * [Generators](/docs/shopify_app/generators.md)
  * [ScriptTags](/docs/shopify_app/script-tags.md)
  * [Session repository](/docs/shopify_app/session-repository.md)
  * [Handling changes in access scopes](/docs/shopify_app/handling-access-scopes-changes.md)
  * [Testing](/docs/shopify_app/testing.md)
  * [Webhooks](/docs/shopify_app/webhooks.md)
  * [Content Security Policy](/docs/shopify_app/content-security-policy.md)

### Engine

Mounting the Shopify App Rails Engine provides the following routes. These routes are configured to help install your application on shops and implement OAuth.

| Verb   | Route                    | Action             |
|   ---: | :---                     | :---               |
| `GET`  | `/login`                 | Login              |
| `POST` | `/login`                 | Login              |
| `GET`  | `/auth/shopify/callback` | OAuth redirect URI |
| `GET`  | `/logout`                | Logout             |
| `POST` | `/webhooks/:type`        | Webhook callback   |

These routes are configurable. See the more detailed [*Engine*](/docs/shopify_app/engine.md) documentation to learn how you can customize the login URL or mount the Shopify App Rails engine at nested routes.

To learn more about how this gem authenticates with Shopify, see [*Authentication*](/docs/shopify_app/authentication.md).

### API Versioning

[Shopify's API is versioned](https://shopify.dev/concepts/about-apis/versioning). With Shopify App `v1.11.0`, the included Shopify API gem allows developers to specify and update the Shopify API version they want their app or service to use. The Shopify API gem also surfaces warnings to Rails apps about [deprecated endpoints, GraphQL fields and more](https://shopify.dev/concepts/about-apis/versioning#deprecation-practices).

See the [Shopify API gem README](https://github.com/Shopify/shopify-api-ruby/) for more information.
