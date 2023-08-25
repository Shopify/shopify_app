# Authentication

The Shopify App gem implements [OAuth 2.0](https://shopify.dev/tutorials/authenticate-with-oauth) to get [session tokens](https://shopify.dev/concepts/about-apis/authentication#api-access-modes). These are used to authenticate requests made by the app to the Shopify API.

By default, the gem generates an embedded app frontend that uses [Shopify App Bridge](https://shopify.dev/tools/app-bridge) to fetch [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens). Session tokens are used by the embedded app to make authenticated requests to the app backend. 

See [*Getting started with session token authentication*](https://shopify.dev/docs/apps/auth/oauth/session-tokens/getting-started) to learn more. 

> ⚠️ Be sure you understand the differences between the types of authentication schemes before reading this guide.

#### Table of contents

* [OAuth callback](#oauth-callback)
  * [Customizing callback controller](#customizing-callback-controller)
* [Run jobs after the OAuth flow](#run-jobs-after-the-oauth-flow)
* [Rotate API credentials](#rotate-api-credentials)
* [Making authenticated API requests after authorization](#making-authenticated-api-requests-after-authorization)

## OAuth callback

>️ **Note:** In Shopify App version 8.4.0, we have extracted the callback logic in its own controller. If you are upgrading from a version older than 8.4.0 the callback action and related helper methods were defined in `ShopifyApp::SessionsController` ==> you will have to extend `ShopifyApp::CallbackController` instead and port your logic to the new controller.

Upon completing the OAuth flow, Shopify calls the app at `ShopifyApp.configuration.login_callback_url`.

The default callback controller [`ShopifyApp::CallbackController`](../../app/controllers/shopify_app/callback_controller.rb) provides the following behaviour:

1. Logging into the shop and resetting the session
2. Storing the session to the `SessionRepository`
3. [Installing Webhooks](/docs/shopify_app/webhooks.md)
4. [Setting Scripttags](/docs/shopify_app/script-tags.md)
5. [Run jobs after the OAuth flow](#run-jobs-after-the-oauth-flow)
6. Redirecting to the return address


#### Customizing callback controller
If the app needs to do some extra work, it can define and configure the route to a custom callback controller.
Inheriting from `ShopifyApp::CallbackController` and hook into or override any of the defined helper methods.

Example:

1. Create the new custom callback controller
```ruby
# web/app/controllers/my_custom_callback_controller.rb

class MyCustomCallbackController < ShopifyApp::CallbackController
  private

  def install_webhooks(session)
    # My custom override/definition to install webhooks
  end
end
```

2. Override callback routing to this controller

```ruby
# web/config/routes.rb

Rails.application.routes.draw do
  root to: "home#index"

  # Overriding the callback controller to the new custom one.
  # This must be added before mounting the ShopifyApp::Engine
  get ShopifyApp.configuration.login_callback_url, to: 'my_custom_callback#callback'

  mount ShopifyApp::Engine, at: "/api"

  # other routes
end
```

### Run jobs after the OAuth flow

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
  config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: true }
end
```

We've also provided a generator which creates a skeleton job and updates the initializer for you:

```
bin/rails g shopify_app:add_after_authenticate_job
```

If you want to perform that action only once, e.g. send a welcome email to the user when they install the app, you should make sure that this action is idempotent, meaning that it won't have an impact if run multiple times.

## Rotate API credentials

If your Shopify secret key is leaked, you can use the `RotateShopifyTokenJob` to perform [API Credential Rotation](https://help.shopify.com/en/api/getting-started/authentication/oauth/api-credential-rotation).

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

## Making authenticated API requests after authorization
After the app is installed onto a shop and has been granted all necessary permission, a new session record will be added to `SessionRepository#shop_storage`, or `SessionRepository#user_storage` if online sessions are enabled.

When your app needs to make API requests to Shopify, `ShopifyApp`'s `ActiveSupport` controller concerns can help you retrieve the active session token from the repository to make the authenticate API call.

- ⚠️ See [Sessions](./sessions.md) page to understand how sessions work.
- ⚠️ See [Controller Concerns](./controller-concerns.md) page to understand when to use which concern.
