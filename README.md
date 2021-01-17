Shopify App
===========
[![Version][gem]][gem_url] [![Build Status](https://github.com/Shopify/shopify_app/workflows/CI/badge.svg)](https://github.com/Shopify/shopify_app/actions?query=workflow%3ACI)

[gem]: https://img.shields.io/gem/v/shopify_app.svg
[gem_url]: https://rubygems.org/gems/shopify_app


Shopify Application Rails engine and generator

### NOTE: Rails 6.1 or above is not yet supported due to the new `cookies_same_site_protection` setting.

#### NOTE: Versions 8.0.0 through 8.2.3 contained a CSRF vulnerability that was addressed in version 8.2.4. Please update to version 8.2.4 if you're using an old version.

Table of Contents
-----------------
- [Introduction](#introduction)
- [Become a Shopify App Developer](#become-a-shopify-app-developer)
- [Installation](#installation)
- [Generators](#generators)
- [Mounting the Engine](#mounting-the-engine)
- [Authentication](#authentication)
- [WebhooksManager](#webhooksmanager)
- [ScripttagsManager](#scripttagsmanager)
- [RotateShopifyTokenJob](#rotateshopifytokenjob)
- [App Tunneling](#app-tunneling)
- [AppProxyVerification](#appproxyverification)
- [Troubleshooting](#troubleshooting)
- [Testing an embedded app outside the Shopify admin](#testing-an-embedded-app-outside-the-shopify-admin)
- [Migration to 13.0.0](#migrating-to-1300)
- [Questions or problems?](#questions-or-problems)
- [Rails 6 Compatibility](#rails-6-compatibility)
- [Upgrading from 8.6 to 9.0.0](#upgrading-from-86-to-900)

Introduction
-----------
Get started with the [Shopify Admin API](https://help.shopify.com/en/api/getting-started) faster; This gem includes a Rails Engine and generators for writing Rails applications using the Shopify API. The Engine provides a SessionsController and all the required code for authenticating with a shop via OAuth (other authentication methods are not supported).

*Note: It's recommended to use this on a new Rails project so that the generator won't overwrite/delete your files.*

Learn how to create and deploy a new Shopify App to Heroku with our [quickstart guide](https://github.com/Shopify/shopify_app/blob/master/docs/Quickstart.md), or dive in in less than 5 minutes with this quickstart video:

[https://www.youtube.com/watch?v=yGxeoAHlQOg](https://www.youtube.com/watch?v=yGxeoAHlQOg)

Become a Shopify App Developer
--------------------------------
To become a Shopify App Developer, you'll need a [Shopify Partner account.](http://shopify.com/partners) If you don't have a Shopify Partner account, head to http://shopify.com/partners to create one before you start.

Once you have a Partner account, [create a new application in the Partner Dashboard](https://help.shopify.com/en/api/tools/partner-dashboard/your-apps) to get an API key and other API credentials.

To create an application for development set your new app's `App URL` to the URL provided by [your tunnel](#app-tunneling), ensuring that you use `https://`. If you are not planning to embed your app inside the Shopify admin or receive webhooks, set your redirect URL to `http://localhost:3000/` and the `Whitelisted redirection URL(s)` to contain `<App URL>/auth/shopify/callback`.

Installation
------------
To get started, add `shopify_app` to your Gemfile and run `bundle install`:

``` sh
# Create a new rails app
$ rails new my_shopify_app
$ cd my_shopify_app

# Add the gem shopify_app to your Gemfile
$ bundle add shopify_app
```

Now we are ready to run any of the [generators](#generators) included with `shopify_app`. The following section explains the generators and what you can do with them.


#### Rails Compatibility

The latest version of shopify_app is compatible with Rails `>= 5`. Use version `<= v7.2.8` if you need to work with Rails 4.


Generators
----------

### API Keys
<!-- This anchor name `#api-keys` is linked to from user output in `templates/shopify_app.rb.tt` so beware of changing -->
Before starting the app, you'll need to ensure it can read the Shopify environment variables `SHOPIFY_API_KEY` and `SHOPIFY_API_SECRET`.

In a development environment, a common approach is to use the [dotenv-rails](https://github.com/bkeepers/dotenv) gem, along with an `.env` file in the following format:

```
SHOPIFY_API_KEY=your api key
SHOPIFY_API_SECRET=your api secret
```

These values can be found on the "App Setup" page in the [Shopify Partners Dashboard][dashboard].
(If you are using [shopify-app-cli](https://github.com/Shopify/) this `.env` file will be created automatically).
If you are checking your code into a code repository, ensure your `.gitignore` prevents your `.env` file from being checked into any publicly accessible code.

### Default Generator

The default generator will run the `install`, `shop`, `authenticated_controller`, and `home_controller` generators. This is the recommended way to start a new app from scratch:

```sh
$ rails generate shopify_app
```

After running the generator, you will need to run `rails db:migrate` to add new tables to your database. You can start your app with `bundle exec rails server` and install your app by visiting `http://localhost` in your web browser.


### Install Generator

```sh
$ rails generate shopify_app:install
```

Options include:
* `application_name` - the name of your app, it can be supplied with or without double-quotes if a whitespace is present. (e.g. `--application_name Example App` or `--application_name "Example App"`)
* `scope` - the OAuth access scope required for your app, e.g. **read_products, write_orders**. *Multiple options* need to be delimited by a comma-space and can be supplied with or without double-quotes
(e.g. `--scope read_products, write_orders, write_products` or `--scope "read_products, write_orders, write_products"`)
For more information, refer to the [docs](http://docs.shopify.com/api/tutorials/oauth).
* `embedded` - the default is to generate an [embedded app](http://docs.shopify.com/embedded-app-sdk), if you want a legacy non-embedded app then set this to false, `--embedded false`
* __[Not recommended for embedded apps]__ `with-cookie-authentication` - sets up the authentication strategy of the app to use cookies. By default, it uses JWT based session tokens.

You can update any of these settings later on easily; the arguments are simply for convenience.

The generator adds ShopifyApp and the required initializers to the host Rails application.

After running the `install` generator, you can start your app with `bundle exec rails server` and install your app by visiting localhost.


### Home Controller Generator

```sh
$ rails generate shopify_app:home_controller
```

This generator creates an example home controller and view which fetches and displays products using the Shopify API. By default, this generator creates an unauthenticated home_controller and a sample protected products_controller.

Options include:
* __[Not recommended for embedded apps]__ `with-cookie-authentication` - This flag generates an authenticated home_controller, where the authentication strategy relies on cookies. By default, this generator creates an unauthenticated home_controller and protected sample products_controller.

### Products Controller Generator

```sh
$ rails generate shopify_app:products_controller
```

This generator creates an example products API controller to fetch products using the Shopify API.

### App Proxy Controller Generator

```sh
$ rails generate shopify_app:app_proxy_controller
```

This optional generator, not included with the default generator, creates the app proxy controller to handle proxy requests to the app from your shop storefront, modifies 'config/routes.rb' with a namespace route, and an example view which displays current shop information using the LiquidAPI.

### Marketing Extension Generator

```sh
$ rails generate shopify_app:add_marketing_activity_extension
```

This will create a controller with the endpoints required to build a [marketing activities extension](https://help.shopify.com/en/api/embedded-apps/app-extensions/shopify-admin/marketing-activities). The extension will be generated with a base URL at `/marketing_activities`, which should also be configured in partners.

### Controllers, Routes and Views

The last group of generators are for your convenience if you want to start overriding code included as part of the Rails engine. For example, by default the engine provides a simple SessionController, if you run the `rails generate shopify_app:controllers` generator then this code gets copied out into your app so you can start adding to it. Routes and views follow the exact same pattern.

Mounting the Engine
-------------------

Mounting the Engine will provide the basic routes to authenticating a shop with your application. By default it will provide:

| Verb   | Route                         | Action                       |
|--------|-------------------------------|------------------------------|
|GET     |'/login'                       |Login                         |
|POST    |'/login'                       |Login                         |
|GET     |'/auth/shopify/callback'       |Authenticate Callback         |
|GET     |'/logout'                      |Logout                        |
|POST    |'/webhooks/:type'              |Webhook Callback              |

### Nested Routes

The engine may also be mounted at a nested route, for example:

```ruby
mount ShopifyApp::Engine, at: '/nested'
```

This will create the Shopify engine routes under the specified subpath. You'll also need to make some updates to your `shopify_app.rb` and `omniauth.rb` initializers. First, update the shopify_app initializer to include a custom `root_url` e.g.:

```ruby
ShopifyApp.configure do |config|
  config.root_url = '/nested'
end
```

then update the omniauth initializer to include a custom `callback_path` e.g.:

```ruby
provider :shopify,
  ShopifyApp.configuration.api_key,
  ShopifyApp.configuration.secret,
  scope: ShopifyApp.configuration.scope,
  callback_path: '/nested/auth/shopify/callback'
```

You may also need to change your `config/routes.rb` to render a view for `/nested`, since this is what will be rendered in the Shopify Admin of any shops that have installed your app.  The engine itself doesn't have a view for this, so you'll need something like this:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root :to => 'something_else#index'
  get "/nested", to: "home#index"
  mount ShopifyApp::Engine, at: '/nested'
end
```

Finally, note that if you do this, to add your app to a store, you must navigate to `/nested` in order to render the `Enter your shop domain to log in or install this app.` UI.

### Custom login URL

While you can customize the login view by creating a `/app/views/shopify_app/sessions/new.html.erb` file, you may also want to customize the URL entirely. You can modify your `shopify_app.rb` initializer to provide a custom `login_url` e.g.:

```ruby
ShopifyApp.configure do |config|
  config.login_url = 'https://my.domain.com/nested/login'
end
```

Authentication
--------------

### Callback

Upon completing the authentication flow, Shopify calls the app at the `callback_path` mentioned before. If the app needs to do some extra work, it can define and configure the route to a custom callback controller, inheriting from `ShopifyApp::CallbackController` and hook into or override any of the defined helper methods. The default callback controller already provides the following behaviour:
* Logging into the shop and resetting the session
* [Installing Webhooks](https://github.com/Shopify/shopify_app#webhooksmanager)
* [Setting Scripttags](https://github.com/Shopify/shopify_app#scripttagsmanager)
* [Performing the AfterAuthenticate Job](https://github.com/Shopify/shopify_app#afterauthenticatejob)
* Redirecting to the return address

**Note that starting with version 8.4.0, we have extracted the callback logic in its own controller. If you are upgrading from a version older than 8.4.0 the callback action and related helper methods were defined in `ShopifyApp::SessionsController` ==> you will have to extend `ShopifyApp::CallbackController` instead and port your logic to the new controller.**

### ShopifyApp::SessionRepository

`ShopifyApp::SessionRepository` allows you as a developer to define how your sessions are stored and retrieved for shops. The `SessionRepository` is configured in the `config/initializers/shopify_app.rb` file and can be set to any object that implements `self.store(auth_session, *args)` which stores the session and returns a unique identifier and `self.retrieve(id)` which returns a `ShopifyAPI::Session` for the passed id. These methods are already implemented as part of the `ShopifyApp::SessionStorage` concern but can be overridden for custom implementation.

#### Shop-based token storage
Storing tokens on the store model means that any user login associated with the store will have equal access levels to whatever the original user granted the app.
```sh
$ rails generate shopify_app:shop_model
```
This will generate a shop model which will be the storage for the tokens necessary for authentication.

#### User-based token storage
A more granular control over the level of access per user on an app might be necessary, to which the shop-based token strategy is not sufficient. Shopify supports a user-based token storage strategy where a unique token to each user can be managed. Shop tokens must still be maintained if you are running background jobs so that you can make use of them when necessary.
```sh
$ rails generate shopify_app:shop_model
$ rails generate shopify_app:user_model
```
This will generate a shop model and user model, which will be the storage for the tokens necessary for authentication.

The current Shopify user will be stored in the rails session at `session[:shopify_user]`

Read more about Online vs. Offline access [here](https://help.shopify.com/api/getting-started/authentication/oauth).

#### Migrating from shop-based to user-based token strategy
1. Run the `user_model` generator as mentioned above.
2. Ensure that both your `Shop` model and `User` model includes the necessary concerns `ShopifyApp::ShopSessionStorage` and `ShopifyApp::UserSessionStorage`.
3. Make changes to 2 initializer files as shown below:
```ruby
# In the `omniauth.rb` initializer:
provider :shopify,
  ...
  setup: lambda { |env|
    ...
    # Add this line
    strategy.options[:per_user_permissions] = strategy.session[:user_tokens]
    ...
  }

# In the `shopify_app.rb` initializer:
config.shop_session_repository = {YOUR_SHOP_MODEL_CLASS}
config.user_session_repository = {YOUR_USER_MODEL_CLASS}
```

### Authenticated

The engine provides a `ShopifyApp::Authenticated` concern which should be included in any controller that is intended to be behind Shopify OAuth. It adds `before_action`s to ensure that the user is authenticated and will redirect to the Shopify login page if not. It is best practice to include this concern in a base controller inheriting from your `ApplicationController`, from which all controllers that require Shopify authentication inherit.

For backwards compatibility, the engine still provides a controller called `ShopifyApp::AuthenticatedController` which includes the `ShopifyApp::Authenticated` concern. Note that it inherits directly from `ActionController::Base`, so you will not be able to share functionality between it and your application's `ApplicationController`.

### EnsureAuthenticatedLinks

The `ShopifyApp::EnsureAuthenticatedLinks` concern helps authenticate users that access protected pages of your app directly.

Include this concern in your app's `AuthenticatedController` if your app uses session tokens with [Turbolinks](https://shopify.dev/tutorials/authenticate-server-side-rendered-apps-with-session-tokens-app-bridge-turbolinks). It adds a `before_action` filter that detects whether a session token is present or not. If a session is not found, the user is redirected to your app's splash page path (`root_path`) along with `return_to` and `shop` parameters.

Example `AuthenticatedController`:

```rb
class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureAuthenticatedLinks
  include ShopifyApp::Authenticated
end
```

### AfterAuthenticate Job

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

API Versioning
--------------

Shopify's API is versioned, and you can [read about that process in the Shopify Developers documentation page](https://shopify.dev/concepts/about-apis/versioning).

Since shopify_app gem version 1.11.0, the included shopify_api gem has also been updated to allow you to easily set and switch what version of the Shopify API you want your app or service to use, as well as surface warnings to Rails apps about [deprecated endpoints, GraphQL fields and more](https://shopify.dev/concepts/about-apis/versioning#deprecation-practices).

See the [shopify_api gem README](https://github.com/Shopify/shopify_api/) for more details.

WebhooksManager
---------------

ShopifyApp can manage your app's webhooks for you if you set which webhooks you require in the initializer:

```ruby
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'carts/update', address: 'https://example-app.com/webhooks/carts_update'}
  ]
end
```

When the OAuth callback is completed successfully, ShopifyApp will queue a background job which will ensure all the specified webhooks exist for that shop. Because this runs on every OAuth callback, it means your app will always have the webhooks it needs even if the user uninstalls and re-installs the app.

ShopifyApp also provides a WebhooksController that receives webhooks and queues a job based on the received topic. For example, if you register the webhook from above, then all you need to do is create a job called `CartsUpdateJob`. The job will be queued with 2 params: `shop_domain` and `webhook` (which is the webhook body).

If you would like to namespace your jobs, you may set `webhook_jobs_namespace` in the config. For example, if your app handles webhooks from other ecommerce applications as well, and you want Shopify cart update webhooks to be processed by a job living in `jobs/shopify/webhooks/carts_update_job.rb` rather than `jobs/carts_update_job.rb`):

```ruby
ShopifyApp.configure do |config|
  config.webhook_jobs_namespace = 'shopify/webhooks'
end
```

If you are only interested in particular fields, you can optionally filter the data sent by Shopify by specifying the `fields` parameter in `config/webhooks`. Note that you will still receive a webhook request from Shopify every time the resource is updated, but only the specified fields will be sent.

```ruby
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'products/update', address: 'https://example-app.com/webhooks/products_update', fields: ['title', 'vendor']}
  ]
end
```

If you'd rather implement your own controller then you'll want to use the WebhookVerification module to verify your webhooks, example:

```ruby
class CustomWebhooksController < ApplicationController
  include ShopifyApp::WebhookVerification

  def carts_update
    params.permit!
    SomeJob.perform_later(shop_domain: shop_domain, webhook: webhook_params.to_h)
    head :no_content
  end

  private

  def webhook_params
    params.except(:controller, :action, :type)
  end
end
```

The module skips the `verify_authenticity_token` before_action and adds an action to verify that the webhook came from Shopify. You can now add a post route to your application, pointing to the controller and action to accept the webhook data from Shopify.

The WebhooksManager uses ActiveJob. If ActiveJob is not configured then by default Rails will run the jobs inline. However, it is highly recommended to configure a proper background processing queue like Sidekiq or Resque in production.

ShopifyApp can create webhooks for you using the `add_webhook` generator. This will add the new webhook to your config and create the required job class for you.

```
rails g shopify_app:add_webhook -t carts/update -a https://example.com/webhooks/carts_update
```

Where `-t` is the topic and `-a` is the address the webhook should be sent to.

ScripttagsManager
-----------------

As with webhooks, ShopifyApp can manage your app's scripttags for you by setting which scripttags you require in the initializer:

```ruby
ShopifyApp.configure do |config|
  config.scripttags = [
    {event:'onload', src: 'https://my-shopifyapp.herokuapp.com/fancy.js'},
    {event:'onload', src: ->(domain) { dynamic_tag_url(domain) } }
  ]
end
```

You also need to have write_script_tags permission in the config scope in order to add script tags automatically:

```ruby
 config.scope = '... , write_script_tags'
```

Scripttags are created in the same way as the Webhooks, with a background job which will create the required scripttags.

If `src` responds to `call` its return value will be used as the scripttag's source. It will be called on scripttag creation and deletion.

RotateShopifyTokenJob
---------------------

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

⚠️ Note: if you are updating `shopify_app` from a version prior to 8.4.2 (and do not wish to run the default/install generator again), you will need to add [the following line](https://github.com/Shopify/shopify_app/blob/4f7e6cca2a472d8f7af44b938bd0fcafe4d8e88a/lib/generators/shopify_app/install/templates/shopify_provider.rb#L18) to `config/initializers/omniauth.rb`:

```ruby
strategy.options[:old_client_secret] = ShopifyApp.configuration.old_secret
```

App Tunneling
-------------

Your local app needs to be accessible from the public Internet in order to install it on a Shopify store, to use the [App Proxy Controller](#app-proxy-controller-generator) or receive Webhooks.

Use a tunneling service like [ngrok](https://ngrok.com/), [Forward](https://forwardhq.com/), [Beeceptor](https://beeceptor.com/), [Mockbin](http://mockbin.org/), or [Hookbin](https://hookbin.com/) to make your development environment accessible to the internet.

For example with [ngrok](https://ngrok.com/), run this command to set up a tunnel proxy to Rails' default port:

```sh
ngrok http 3000
```

AppProxyVerification
--------------------

The engine provides a mixin for verifying incoming HTTP requests sent via an App Proxy. Any controller that `include`s `ShopifyApp::AppProxyVerification` will verify that each request has a valid `signature` query parameter that is calculated using the other query parameters and the app's shared secret.

### Recommended Usage

The App Proxy Controller Generator automatically adds the mixin to the generated app_proxy_controller.rb
Additional controllers for resources within the App_Proxy namespace, will need to include the mixin like so:

```ruby
# app/controllers/app_proxy/reviews_controller.rb
class ReviewsController < ApplicationController
  include ShopifyApp::AppProxyVerification
  # ...
end
```

Create your app proxy URL in the [Shopify Partners' Dashboard][dashboard], making sure to point it to `https://your_app_website.com/app_proxy`.
![Creating an App Proxy](/images/app-proxy-screenshot.png)

App Bridge
---

A basic example of using [App Bridge][app-bridge] is included in the install generator. An app instance is automatically initialized in [shopify_app.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/shopify_app.js) and [flash_messages.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/flash_messages.js) converts Rails [flash messages](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html) to App Bridge Toast actions automatically. By default, this library is included via [unpkg in the embedded_app layout](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/embedded_app.html.erb#L27). For more advanced uses it is recommended to [install App Bridge via npm or yarn](https://help.shopify.com/en/api/embedded-apps/app-bridge/getting-started#set-up-shopify-app-bridge-in-your-app).

Troubleshooting
---------------

see [TROUBLESHOOTING.md](https://github.com/Shopify/shopify_app/blob/master/docs/Troubleshooting.md)

Using Test Helpers inside your Application
-----------------------------------------

A test helper that will allow you to test `ShopifyApp::WebhookVerification` in the controller from your app, to use this test, you need to `require` it directly inside your app `test/controllers/webhook_verification_test.rb`.

```ruby
    require 'test_helper'
    require 'action_controller'
    require 'action_controller/base'
    require 'shopify_app/test_helpers/webhook_verification_helper'
```

Or you can require in your `test/test_helper.rb`.

```ruby
  ENV['RAILS_ENV'] ||= 'test'
  require_relative '../config/environment'
  require 'rails/test_help'
  require 'byebug'
  require 'shopify_app/test_helpers/all'
```

With `lib/shopify_app/test_helpers/all'` more tests can be added and will only need to be required in once in your library.


Testing an embedded app outside the Shopify admin
-------------------------------------------------

By default, loading your embedded app will redirect to the Shopify admin, with the app view loaded in an `iframe`. If you need to load your app outside of the Shopify admin (e.g., for performance testing), you can change `forceRedirect: true` to `false` in `ShopifyApp.init` block in the `embedded_app` view. To keep the redirect on in production but off in your `development` and `test` environments, you can use:

```javascript
forceRedirect: <%= Rails.env.development? || Rails.env.test? ? 'false' : 'true' %>
```

Migrating to 13.0.0
-------------------

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

Questions or problems?
----------------------

- [Ask questions!](https://ecommerce.shopify.com/c/shopify-apis-and-technology)
- [Read the docs!](https://help.shopify.com/api/guides)
- And don't forget to check the [Changelog](https://github.com/Shopify/shopify_app/blob/master/CHANGELOG.md) too!

Upgrading to 11.7.0
---------------------------

### Session storage method signature breaking change
If you override `def self.store(auth_session)` method in your session storage model (e.g. Shop), the method signature has changed to `def self.store(auth_session, *args)` in order to support user-based token storage. Please update your method signature to include the second argument.

Rails 6 Compatibility
---------------------

### Disable Webpacker
If you are using sprockets in rails 6 or want to generate a shopify_app without webpacker run the install task by running

```
SHOPIFY_APP_DISABLE_WEBPACKER=1 rails generate shopify_app
```

and then in your ShopifyApp configuration block, add

```
ShopifyApp.configure do |config|
  config.disable_webpacker = true
end
```

Upgrading from 8.6 to 9.0.0
---------------------------

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
