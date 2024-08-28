# Authentication

The Shopify App gem implements [OAuth 2.0](https://shopify.dev/tutorials/authenticate-with-oauth) to get [session tokens](https://shopify.dev/concepts/about-apis/authentication#api-access-modes). These are used to authenticate requests made by the app to the Shopify API.

By default, the gem generates an embedded app frontend that uses [Shopify App Bridge](https://shopify.dev/tools/app-bridge) to fetch [session tokens](https://shopify.dev/concepts/apps/building-embedded-apps-using-session-tokens). Session tokens are used by the embedded app to make authenticated requests to the app backend. 

See [*Getting started with session token authentication*](https://shopify.dev/docs/apps/auth/oauth/session-tokens/getting-started) to learn more. 

> ⚠️ Be sure you understand the differences between the types of authentication schemes before reading this guide.

#### Table of contents

* [Supported types of OAuth Flow](#supported-types-of-oauth)
  * [Token Exchange](#token-exchange)
  * [Authorization Code Grant Flow](#authorization-code-grant-flow)
    * [OAuth callback](#oauth-callback)
      * [Customizing callback controller](#customizing-callback-controller)
    * [Detecting scope changes](#detecting-scope-changes-1)
* [Run jobs after the OAuth flow](#post-authenticate-tasks)
* [Rotate API credentials](#rotate-api-credentials)
* [Making authenticated API requests after authorization](#making-authenticated-api-requests-after-authorization)

## Supported types of OAuth
> [!TIP]
> If you are building an embedded app, we **strongly** recommend using [Shopify managed installation](https://shopify.dev/docs/apps/auth/installation#shopify-managed-installation)
with [token exchange](#token-exchange) instead of the authorization code grant flow.

1. [Token Exchange](#token-exchange)
    - Recommended and is only available for embedded apps
    - Doesn't require redirects, which makes authorization faster and prevents flickering when loading the app
    - Access scope changes are handled by Shopify when you use [Shopify managed installation](https://shopify.dev/docs/apps/auth/installation#shopify-managed-installation)
2. [Authorization Code Grant Flow](#authorization-code-grant-flow)
    - Suitable for non-embedded apps
    - Installations, and access scope changes are managed by the app

## Token Exchange

OAuth process by exchanging the current user's [session token (shopify id token)](https://shopify.dev/docs/apps/auth/session-tokens) for an
[access token](https://shopify.dev/docs/apps/auth/access-token-types/online.md) to make
authenticated Shopify API queries. This will replace authorization code grant flow completely when your app is configured with [Shopify managed installation](https://shopify.dev/docs/apps/auth/installation#shopify-managed-installation).

To enable token exchange authorization strategy, you can follow the steps in ["New embedded app authorization strategy"](/README.md#new-embedded-app-authorization-strategy).
Upon completion of the token exchange to get the access token, [post authenticated tasks](#post-authenticate-tasks) will be run.

Learn more about:
- [How token exchange works](https://shopify.dev/docs/apps/auth/get-access-tokens/token-exchange)
- [Using Shopify managed installation](https://shopify.dev/docs/apps/auth/installation#shopify-managed-installation)
- [Configuring access scopes through the Shopify CLI](https://shopify.dev/docs/apps/tools/cli/configuration)

#### Handling invalid access tokens
If the access token used to make an API call is invalid, the token exchange strategy will handle the error and try to retrieve a new access token before retrying 
the same operation. 
See ["Re-fetching an access token when API returns Unauthorized"](/docs/shopify_app/sessions.md#re-fetching-an-access-token-when-api-returns-unauthorized) section for more information.

#### Detecting scope changes

##### Shopify managed installation
If your access scopes are [configured through the Shopify CLI](https://shopify.dev/docs/apps/tools/cli/configuration), scope changes will be handled by Shopify automatically.
Learn more about [Shopify managed installation](https://shopify.dev/docs/apps/auth/installation#shopify-managed-installation).
Using token exchange will ensure that the access token retrieved will always have the latest access scopes granted by the user.

## Authorization Code Grant Flow
Authorization code grant flow is the OAuth flow that requires the app to redirect the user 
to Shopify for installation/authorization of the app to access the shop's data. It is still required for apps that are not embedded.

To perform [authorization code grant flow](https://shopify.dev/docs/apps/auth/get-access-tokens/authorization-code-grant), you app will need to handle
[begin OAuth](#begin-oauth) and [OAuth callback](#oauth-callback) routes.

### Begin OAuth
ShopifyApp automatically redirects the user to Shopify to complete OAuth to install the app when the `ShopifyApp.configuration.login_url` is reached.
Behind the scenes the ShopifyApp gem starts the process by calling `ShopifyAPI::Auth::Oauth.begin_auth` to build the 
redirect URL with necessary parameters like the OAuth callback URL, scopes requested, type of access token (offline or online) requested, etc.
The ShopifyApp gem then redirect the merchant to Shopify, to ask for permission to install the app. (See [ShopifyApp::SessionsController.redirect_to_begin_oauth](https://github.com/Shopify/shopify_app/blob/main/app/controllers/shopify_app/sessions_controller.rb#L76-L96)
for detailed implementation)

### OAuth callback

Shopify will redirect the merchant back to your app's callback URL once they approve the app installation.
Upon completing the OAuth flow, Shopify calls the app at `ShopifyApp.configuration.login_callback_url`. (This was provided to Shopify in the OAuth begin URL parameters)

The default callback controller [`ShopifyApp::CallbackController`](../../app/controllers/shopify_app/callback_controller.rb) provides the following behaviour:

1. Logging into the shop and resetting the session
2. Storing the session to the `SessionRepository`
3. [Post authenticate tasks](#post-authenticate-tasks)
4. Redirecting to the return address

#### Customizing callback controller
If you need to define a custom callback controller to handle your app's use case, you can configure the callback route to your controller.

Example:

1. Create the new custom callback controller
```ruby
# web/app/controllers/my_custom_callback_controller.rb

class MyCustomCallbackController
  def callback
    # My custom callback logic
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

### Detecting scope changes
When the OAuth process is completed, the created session has a `scope` field which holds all of the access scopes that were requested from the merchant at the time.

When an app's access scopes change, it needs to request merchants to go through OAuth again to renew its permissions.

See [Handling changes in access scopes](/docs/shopify_app/handling-access-scopes-changes.md).

## Post Authenticate tasks
After authentication is complete, a few tasks are run by default by PostAuthenticateTasks:
1. [Installing Webhooks](/docs/shopify_app/webhooks.md)
2. [Run configured after_authenticate_job](#after_authenticate_job)

The [PostAuthenticateTasks](https://github.com/Shopify/shopify_app/blob/main/lib/shopify_app/auth/post_authenticate_tasks.rb)
class is responsible for triggering the webhooks manager for webhooks registration, and enqueue jobs from [after_authenticate_job](#after_authenticate_job).

If you simply need to enqueue more jobs to run after authenticate, use [after_authenticate_job](#after_authenticate_job) to define these jobs.

If your post authentication tasks is more complex and is different than just installing webhooks and enqueuing jobs,
you can customize the post authenticate tasks by creating a new class that has a `self.perform(session)` method,
and configuring `custom_post_authenticate_tasks` in the initializer.

```ruby
# my_custom_post_authenticate_task.rb
class MyCustomPostAuthenticateTask
  def self.perform(session)
    # This will be triggered after OAuth callback and token exchange completion
  end
end

# config/initializers/shopify_app.rb
ShopifyApp.configure do |config|
  config.custom_post_authenticate_tasks = "MyCustomPostAuthenticateTask"
end
```

#### after_authenticate_job

See [`ShopifyApp::AfterAuthenticateJob`](/lib/generators/shopify_app/add_after_authenticate_job/templates/after_authenticate_job.rb).

If your app needs to perform specific actions after the user is authenticated successfully (i.e. every time a new session is created), ShopifyApp can queue or run a job of your choosing. To configure the after authenticate job, update your initializer as follows:

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

Also make sure the old secret is specified when setting up `ShopifyAPI::Context` as well:

```ruby
ShopifyAPI::Context.setup(
  api_key: ShopifyApp.configuration.api_key,
  api_secret_key: ShopifyApp.configuration.secret,
  # ...
  old_api_secret_key: ShopifyApp.configuration.old_secret,
)
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
