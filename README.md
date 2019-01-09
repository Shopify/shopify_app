Shopify App
===========
[![Version][gem]][gem_url] [![Build Status](https://travis-ci.org/Shopify/shopify_app.png)](https://travis-ci.org/Shopify/shopify_app)

[gem]: https://img.shields.io/gem/v/shopify_app.svg
[gem_url]: https://rubygems.org/gems/shopify_app


Shopify Application Rails engine and generator

#### NOTE : Versions 8.0.0 through 8.2.3 contained a CSRF vulnerability that was addressed in version 8.2.4. Please update to version 8.2.4 if you're using an old version.

Table of Contents
-----------------
* [**Description**](#description)
* [**Quickstart**](#quickstart)
* [**Becoming a Shopify App Developer**](#becoming-a-shopify-app-developer)
* [**Installation**](#installation)
  * [Rails Compatibility](#rails-compatibility)
* [**Generators**](#generators)
 * [Default Generator](#default-generator)
 * [Install Generator](#install-generator)
 * [Shop Model Generator](#shop-model-generator)
 * [Home Controller Generator](#home-controller-generator)
 * [App Proxy Controller Generator](#app-proxy-controller-generator)
 * [Controllers, Routes and Views](#controllers-routes-and-views)
* [**Mounting the Engine**](#mounting-the-engine)
* [**Managing Api Keys**](#managing-api-keys)
* [**WebhooksManager**](#webhooksmanager)
* [**ScripttagsManager**](#scripttagsmanager)
* [**AfterAuthenticate Job**](#afterauthenticate-job)
* [**ShopifyApp::SessionRepository**](#shopifyappsessionrepository)
* [**AuthenticatedController**](#authenticatedcontroller)
* [**AppProxyVerification**](#appproxyverification)
 * [Recommended Usage](#recommended-usage)
* [**Troubleshooting**](#troubleshooting)
 * [Generator shopify_app:install hangs](#generator-shopify_appinstall-hangs)
* [**Testing an embedded app outside the Shopify admin**](#testing-an-embedded-app-outside-the-shopify-admin)
* [**App Tunneling**](#app-tunneling)
* [**Questions or problems?**](#questions-or-problems)


Description
-----------
This gem includes a Rails Engine and generators for writing Rails applications using the Shopify API. The Engine provides a SessionsController and all the required code for authenticating with a shop via Oauth (other authentication methods are not supported).

The [example](https://github.com/Shopify/shopify_app/tree/master/example) directory contains an app that was generated with this gem. It also contains sample code demonstrating the usage of the embedded app sdk.

*Note: It's recommended to use this on a new Rails project, so that the generator won't overwrite/delete some of your files.*


Quickstart
----------

Check out this screencast on how to create and deploy a new Shopify App to Heroku in 5 minutes:

[https://www.youtube.com/watch?v=yGxeoAHlQOg](https://www.youtube.com/watch?v=yGxeoAHlQOg)

Or if you prefer text instructions the steps in the video are written out [here](https://github.com/Shopify/shopify_app/blob/master/docs/Quickstart.md)

Becoming a Shopify App Developer
--------------------------------
If you don't have a Shopify Partner account yet head over to http://shopify.com/partners to create one, you'll need it before you can start developing apps.

Once you have a Partner account create a new application to get an Api key and other Api credentials. To create a development application set the Application Callback URL to

```
http://localhost:3000/
```

and the `redirect_uri` to

```
http://localhost:3000/auth/shopify/callback
```

This way you'll be able to run the app on your local machine.

Also note, ShopifyApp creates embedded apps by default, so remember to check `enabled` for the embedded settings.


Installation
------------
To get started add shopify_app to your Gemfile and bundle install

``` sh
# Create a new rails app
$ rails new my_shopify_app
$ cd my_shopify_app

# Add the gem shopify_app to your Gemfile
$ echo "gem 'shopify_app'" >> Gemfile
$ bundle install
```

Now we are ready to run any of the shopify_app generators. The following section explains the generators and what they can do.


#### Rails Compatibility

The lastest version of shopify_app is compatible with Rails `>= 5`. Use version `<= v7.2.8` if you need to work with Rails 4.


Generators
----------

### Default Generator

The default generator will run the `install`, `shop`, and `home_controller` generators. This is the recommended way to start your app.

```sh
$ rails generate shopify_app --api_key <your_api_key> --secret <your_app_secret>
```

After running the generator, you will need to run `rake db:migrate` to add tables to your database. You can start your app with `bundle exec rails server` and install your app by visiting localhost.

### Install Generator

```sh
$ rails generate shopify_app:install

# or optionally with arguments:

$ rails generate shopify_app:install --api_key <your_api_key> --secret <your_app_secret>
```

Other options include:
* `application_name` - the name of your app, it can be supplied with or without double-quotes if a whitespace is present. (e.g. `--application_name Example App` or `--application_name "Example App"`)  
* `scope` - the Oauth access scope required for your app, eg **read_products, write_orders**. *Multiple options* need to be delimited by a comma-space, and can be supplied with or without double-quotes  
(e.g. `--scope read_products, write_orders, write_products` or `--scope "read_products, write_orders, write_products"`)  
For more information, refer the [docs](http://docs.shopify.com/api/tutorials/oauth).
* `embedded` - the default is to generate an [embedded app](http://docs.shopify.com/embedded-app-sdk), if you want a legacy non-embedded app then set this to false, `--embedded false`

You can update any of these settings later on easily, the arguments are simply for convenience.

The generator adds ShopifyApp and the required initializers to the host Rails application.

After running the `install` generator, you can start your app with `bundle exec rails server` and install your app by visiting localhost.


### Shop Model Generator

```sh
$ rails generate shopify_app:shop_model
```

The `install` generator doesn't create any database tables or models for you. If you are starting a new app its quite likely that you will want a shops table and model to store the tokens when your app is installed (most of our internally developed apps do!). This generator creates a shop model and a migration. This model includes the `ShopifyApp::SessionStorage` concern which adds two methods to make it compatible as a `SessionRepository`. After running this generator you'll notice the `session_repository` in your `config/initializers/shopify_app.rb` will be set to the `Shop` model. This means that internally ShopifyApp will try and load tokens from this model.

*Note that you will need to run rake db:migrate after this generator*


### Home Controller Generator

```sh
$ rails generate shopify_app:home_controller
```

This generator creates an example home controller and view which fetches and displays products using the ShopifyAPI


### App Proxy Controller Generator

```sh
$ rails generate shopify_app:app_proxy_controller
```

This optional generator, not included with the default generator, creates the app proxy controller to handle proxy requests to the app from your shop storefront, modifies 'config/routes.rb' with a namespace route, and an example view which displays current shop information using the LiquidAPI


### Controllers, Routes and Views

The last group of generators are for your convenience if you want to start overriding code included as part of the Rails engine. For example by default the engine provides a simple SessionController, if you run the `rails generate shopify_app:controllers` generator then this code gets copied out into your app so you can start adding to it. Routes and views follow the exact same pattern.

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

This will create the Shopify engine routes under the specified subpath. You'll also need to make some updates to your `shopify_app.rb` and `omniauth.rb` initializers. First update the shopify_app initializer to include a custom `root_url` e.g.:

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

### Custom login URL

While you can customize the login view by creating a `/app/views/shopify_app/sessions/new.html.erb` file, you may also want to customize the URL entirely. You can modify your `shopify_app.rb` initializer to provide a custom `login_url` e.g.:

```ruby
ShopifyApp.configure do |config|
  config.login_url = 'https://my.domain.com/nested/login'
end
```

Per User Authentication
-----------------------
To enable per user authentication you need to update the `omniauth.rb` initializer:

```ruby
provider :shopify,
  ShopifyApp.configuration.api_key,
  ShopifyApp.configuration.secret,
  scope: ShopifyApp.configuration.scope,
  per_user_permissions: true
```

The current Shopify user will be stored in the rails session at `session[:shopify_user]`

This will change the type of token that Shopify returns and it will only be valid for a short time. Read more about `Online access` [here](https://help.shopify.com/api/getting-started/authentication/oauth). Note that this means you won't be able to use this token to respond to Webhooks.

Managing Api Keys
-----------------

The `install` generator places your Api credentials directly into the shopify_app initializer which is convenient and fine for development but once your app goes into production **your api credentials should not be in source control**. When we develop apps we keep our keys in environment variables so a production shopify_app initializer would look like this:

```ruby
ShopifyApp.configure do |config|
  config.application_name = 'Your app name' # Optional
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY']
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET']
  config.scope = 'read_customers, write_products'
  config.embedded_app = true
end
```


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

When the oauth callback is completed successfully ShopifyApp will queue a background job which will ensure all the specified webhooks exist for that shop. Because this runs on every oauth callback it means your app will always have the webhooks it needs even if the user uninstalls and re-installs the app.

ShopifyApp also provides a WebhooksController that receives webhooks and queues a job based on the received topic. For example if you register the webhook from above then all you need to do is create a job called `CartsUpdateJob`. The job will be queued with 2 params: `shop_domain` and `webhook` (which is the webhook body).

If you would like to namespace your jobs you may set `webhook_jobs_namespace` in the config. For example if your app handles webhooks from other ecommerce applications as well, and you want Shopify cart update webhooks to be processed by a job living in `jobs/shopify/webhooks/carts_update_job.rb` rather than `jobs/carts_update_job.rb`):

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

If you'd rather implement your own controller then you'll want to use the WebhookVerfication module to verify your webhooks, example:

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

The module skips the `verify_authenticity_token` before_action and adds an action to verify that the webhook came from Shopify. You can now add a post route to your application pointing to the controller and action to accept the webhook data from Shopify.

The WebhooksManager uses ActiveJob, if ActiveJob is not configured then by default Rails will run the jobs inline. However it is highly recommended to configure a proper background processing queue like sidekiq or resque in production.

ShopifyApp can create webhooks for you using the `add_webhook` generator. This will add the new webhook to your config and create the required job class for you.

```
rails g shopify_app:add_webhook -t carts/update -a https://example.com/webhooks/carts_update
```

where `-t` is the topic and `-a` is the address the webhook should be sent to.

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

AfterAuthenticate Job
---------------------

If your app needs to perform specific actions after it is installed ShopifyApp can queue or run a job of your choosing (note that we already provide support for automatically creating Webhooks and Scripttags). To configure the after authenticate job update your initializer as follows:

```ruby
ShopifyApp.configure do |config|
  config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob }
end
```

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

ShopifyApp::SessionRepository
-----------------------------

`ShopifyApp::SessionRepository` allows you as a developer to define how your sessions are retrieved and stored for shops. The `SessionRepository` is configured in the `config/initializers/shopify_app.rb` file and can be set to any object that implements `self.store(shopify_session)` which stores the session and returns a unique identifier and `self.retrieve(id)` which returns a `ShopifyAPI::Session` for the passed id. See either the `ShopifyApp::InMemorySessionStore` class or the `ShopifyApp::SessionStorage` concern for examples.

If you only run the install generator then by default you will have an in memory store but it **won't work** on multi-server environments including Heroku. If you ran all the generators including the shop_model generator then the `Shop` model itself will be the `SessionRepository`. If you look at the implementation of the generated shop model you'll see that this gem provides a concern for the `SessionRepository`. You can use this concern on any model that responds to `shopify_domain` and `shopify_token`.

AuthenticatedController
-----------------------

The engine includes a controller called `ShopifyApp::AuthenticatedController` which inherits from `ActionController::Base`. It adds some before_filters which ensure the user is authenticated and will redirect to the login page if not. It is best practice to have all controllers that belong to the Shopify part of your app inherit from this controller. The HomeController that is generated already inherits from AuthenticatedController.

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

Create your app proxy url in the [Shopify Partners' Dashboard](https://app.shopify.com/services/partners/api_clients), making sure to point it to `https://your_app_website.com/app_proxy`.
![Creating an App Proxy](/images/app-proxy-screenshot.png)

Troubleshooting
---------------

see [TROUBLESHOOTING.md](https://github.com/Shopify/shopify_app/blob/master/docs/Troubleshooting.md)

Testing an embedded app outside the Shopify admin
-------------------------------------------------

By default, loading your embedded app will redirect to the Shopify admin, with the app view loaded in an `iframe`. If you need to load your app outside of the Shopify admin (e.g., for performance testing), you can change `forceRedirect: true` to `false` in `ShopifyApp.init` block in the `embedded_app` view. To keep the redirect on in production but off in your `development` and `test` environments, you can use:

```javascript
forceRedirect: <%= Rails.env.development? || Rails.env.test? ? 'false' : 'true' %>
```

App Tunneling
-------------

For certain features like Application Proxy or Webhooks to receive requests from Shopify, your app needs to be on a publicly visible URL. This can be a hurdle during development or testing on a local machine. Fortunately, this can be overcome by employing a tunneling service like [Forward](https://forwardhq.com/), [RequestBin](https://requestb.in/), [ngrok](https://ngrok.com/) etc. These tools allow you to create a secure tunnel from the public Internet to your local machine.

Tunneling is also useful for working the the embedded app sdk to solve mixed content issues since most tunnles provide ssl.

Questions or problems?
----------------------

- [Ask questions!](https://ecommerce.shopify.com/c/shopify-apis-and-technology)
- [Read the docs!](https://help.shopify.com/api/guides)
