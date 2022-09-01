# Authentication

The Shopify App gem implements [OAuth 2.0](https://shopify.dev/tutorials/authenticate-with-oauth) to get [access tokens](https://shopify.dev/concepts/about-apis/authentication#api-access-modes). These are used to authenticate requests made by the app to the Shopify API. 

By default, the gem generates an embedded app frontend that uses [Shopify App Bridge](https://shopify.dev/tools/app-bridge) to fetch [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens). Session tokens are used by the embedded app to make authenticated requests to the app backend. 

See [*Authenticate an embedded app using session tokens*](https://shopify.dev/tutorials/authenticate-your-app-using-session-tokens) to learn more. 

> ⚠️ Be sure you understand the differences between the types of authentication schemes before reading this guide.

#### Table of contents

[OAuth callback](#oauth-callback)

[Run jobs after the OAuth flow](#run-jobs-after-the-oauth-flow)

[Rotate API credentials](#rotate-api-credentials)

[Available authentication mixins](#available-authentication-mixins)
  * [`ShopifyApp::Authenticated`](#shopifyappauthenticated)
  * [`ShopifyApp::EnsureAuthenticatedLinks`](#shopifyappensureauthenticatedlinks)

## OAuth callback

>️ **Note:** In Shopify App version 8.4.0, we have extracted the callback logic in its own controller. If you are upgrading from a version older than 8.4.0 the callback action and related helper methods were defined in `ShopifyApp::SessionsController` ==> you will have to extend `ShopifyApp::CallbackController` instead and port your logic to the new controller.

Upon completing the OAuth flow, Shopify calls the app at the `callback_path`. If the app needs to do some extra work, it can define and configure the route to a custom callback controller, inheriting from `ShopifyApp::CallbackController` and hook into or override any of the defined helper methods. The default callback controller already provides the following behaviour:
* Logging into the shop and resetting the session
* [Installing Webhooks](/docs/shopify_app/webhooks.md)
* [Setting Scripttags](/docs/shopify_app/script-tags.md)
* [Run jobs after the OAuth flow](#run-jobs-after-the-oauth-flow)
* Redirecting to the return address

## Run jobs after the OAuth flow

See [`ShopifyApp::AfterAuthenticateJob`](/lib/generators/shopify_app/add_after_authenticate_job/templates/after_authenticate_job.rb).

If your app needs to perform specific actions after the user is authenticated successfully (i.e. every time a new session is created), ShopifyApp can queue or run a job of your choosing (note that we already provide support for automatically creating Webhooks and Scripttags). To configure the after authenticate job, update your initializer as follows:

```ruby
ShopifyApp.configure do |config|
  config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob" }
end
```

The job can be configured as either a class or a class name string.

If you need the job to run synchronously add the `inline` flag:

```ruby
ShopifyApp.configure do |config|
  config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
end
```

We've also provided a generator which creates a skeleton job and updates the initializer for you:

```
bin/rails g shopify_app:add_after_authenticate_job
```

If you want to perform that action only once, e.g. send a welcome email to the user when they install the app, you should make sure that this action is idempotent, meaning that it won't have an impact if run multiple times.

## Rotate API credentials

If your Shopify secret key is leaked, you can use the RotateShopifyTokenJob to perform [API Credential Rotation](https://help.shopify.com/en/api/getting-started/authentication/oauth/api-credential-rotation).

Before running the job, you'll need to generate a new secret key from your Shopify Partner dashboard, and update the `/config/initializers/shopify_app.rb` to hold your new and old secret keys:

```ruby
config.secret = Rails.application.secrets.shopify_secret
config.old_secret = Rails.application.secrets.old_shopify_secret
```

We've provided a generator which creates the job and an example rake task:

```sh
bin/rails g shopify_app:rotate_shopify_token_job
```

The generated rake task will be found at `lib/tasks/shopify/rotate_shopify_token.rake` and is provided strictly for example purposes. It might not work with your application out of the box without some configuration.

```ruby
strategy.options[:old_client_secret] = ShopifyApp.configuration.old_secret
```

> **Note:** If you are updating `shopify_app` from a version prior to 8.4.2 (and do not wish to run the default/install generator again), you will need to add [the following line](https://github.com/Shopify/shopify_app/blob/4f7e6cca2a472d8f7af44b938bd0fcafe4d8e88a/lib/generators/shopify_app/install/templates/shopify_provider.rb#L18) to `config/initializers/omniauth.rb`:

## Available authentication mixins

### `ShopifyApp::Authenticated`

The engine provides a [`ShopifyApp::Authenticated`](/app/controllers/concerns/shopify_app/authenticated.rb) concern which should be included in any controller that is intended to be behind Shopify OAuth. It adds `before_action`s to ensure that the user is authenticated and will redirect to the Shopify login page if not. It is best practice to include this concern in a base controller inheriting from your `ApplicationController`, from which all controllers that require Shopify authentication inherit.

*Example:*

```rb
class AuthenticatedController < ApplicationController
  include ShopifyApp::Authenticated
end

class ApiController < AuthenticatedController
  # Actions in this controller are protected
end
```

For backwards compatibility, the engine still provides a controller called `ShopifyApp::AuthenticatedController` which includes the `ShopifyApp::Authenticated` concern. Note that it inherits directly from `ActionController::Base`, so you will not be able to share functionality between it and your application's `ApplicationController`.

#### Embededd apps and `ShopifyApp::Authenticated`

Embedded Shopify Admin apps are unable to use the `ShopifyApp::Authenticated` controller concern. Those who inclue this concern in the `HomeController` or some other embdeded controller will see what looks like an OAuth redirect loop as the `ShopifyApp::Authenticated` concern will be fighting with the App Bridge. For more details on how to handle embeded sessions, refer to [the session token documentation](https://shopify.dev/apps/auth/oauth/session-tokens).

### `ShopifyApp::EnsureAuthenticatedLinks`

The [`ShopifyApp::EnsureAuthenticatedLinks`](/app/controllers/concerns/shopify_app/ensure_authenticated_links.rb) concern helps authenticate users that access protected pages of your app directly.

Include this concern in your app's `AuthenticatedController` if your app uses session tokens with [Turbolinks](https://github.com/turbolinks/turbolinks). It adds a `before_action` filter that detects whether a session token is present or not. If a session token is not found, the user is redirected to your app's splash page path (`root_path`) along with `return_to` and `shop` parameters.

*Example:*

```rb
class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureAuthenticatedLinks
  include ShopifyApp::Authenticated
end
```

See [Authenticate server-side rendered embedded apps using Rails and Turbolinks](https://shopify.dev/tutorials/authenticate-server-side-rendered-embedded-apps-using-rails-and-turbolinks) for more information.
