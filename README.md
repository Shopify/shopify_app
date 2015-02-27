Shopify App      [![Build Status](https://travis-ci.org/Shopify/shopify_app.png)](https://travis-ci.org/Shopify/shopify_app)
===========

Shopify Application Rails engine and generator


Description
-----------
This gem includes some common code and generators for writing Rails applications using the Shopify API.

*Note: It's recommended to use this on a new Rails project, so that the generator won't overwrite/delete some of your files.*


Becoming a Shopify App Developer
--------------------------------
If you don't have a Shopify Partner account yet head over to http://shopify.com/partners to create one, you'll need it before you can start developing apps.

Once you have a Partner account create a new application to get an Api key and other Api credentials. To create a development application set the Application Callback URL to

	http://localhost:3000/login

This way you'll be able to run the app on your local machine.


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


Generators
----------

### Install Generator

```sh
$ rails generate shopify_app:install

# or optionally with arguments:

$ rails generate shopify_app:install -api_key <your_api_key> -secret <your_app_secret>
```

Other options include:
* `scope` - the Oauth access scope required for your app, eg 'read_products, write_orders'. For more information read the [docs](http://docs.shopify.com/api/tutorials/oauth)
* `embedded` - the default is to generate an [embedded app](http://docs.shopify.com/embedded-app-sdk), if you want a legacy non-embedded app then set this to false, `-embedded false`

You can update any of these settings later on easily, the arguments are simply for convenience.

The generator creates a basic SessionsController for authenticating with your shop and a HomeController which displays basic information about your products using the ShopifyAPI. The generated controllers include concerns provided by this gem - in this way code sharing is possible and if some of these core methods are updated everyone can benefit. It is completely safe to override any of the methods provided by this gem in your application.

After running the `install` generator you can start your app with `bundle exec rails server` and install your app by visiting localhost.


### Shop Model Generator

```sh
$ rails generate shopify_app:shop_model
```

The install generator doesn't create any database models for you and if you are starting a new app its quite likely that you will want one (most our internally developed apps do!). This generator creates a simple shop model and a migration. It also create a model called `SessionStorage` which interacts with `ShopifyApp::SessionRepository`. Check out the later section to learn more about `ShopifyApp::SessionRepository`

*Note that you will need to run rake db:migrate after this generator*

### Controllers, Routes and Views

The last group of generators are for your convenience when you want to start overriding code included as part of the Rails engine. For example by default the engine provides a simple SessionController, if you run the `rails generate shopify_app:controllers` generator then this code gets copied out into your app so you can start adding to it. Routes and views follow the exact same pattern.


### Default Generator

If you just run `rails generate shopify_app` then all the generators will be run for you. This is how we do it internally!



Managing Api Keys
-----------------

The `install` generator places your Api credentials directly into the shopify_app initializer which is convient and fine for development but once your app goes into production **your api credentials should not be in source control**. When we develop apps we keep our keys in environment variables so a product shopify_app initializer would look like this:

```ruby
ShopifyApp.configure do |config|
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY']
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET']
  config.scope = 'read_customers, read_orders, write_products'
  config.embedded_app = true
end
```

ShopifyApp::SessionRepository
-----------------------------

`ShopifyApp::SessionRepository` allows you as a developer to define how your sessions are retrieved and
stored for a shop. This can simply be your `Shop` model that stores the API Token and shop name. If
you are using ActiveRecord, then all you need to implement is `self.store(shopify_session)` and
`self.retrieve(id)` in order to store the record on disk or retrieve it for use at a later point.
It is imperative that your store method returns the identifier for the session. Typically this is
just the record ID.

Your ActiveRecord model would look something like this:

```ruby
class Shop < ActiveRecord::Base
  def self.store(session)
    shop = self.new(domain: session.url, token: session.token)
    shop.save!
    shop.id
  end

  def self.retrieve(id)
    if shop = self.where(id: id).first
      ShopifyAPI::Session.new(shop.domain, shop.token)
    end
  end
end
```

By default you will have an in memory store but it **won't work** on multi-server environments since
they won't be sharing the static data that would be required in case your user gets directed to a
different server by your load balancer.

The in memory store also does not behave well on Heroku because the session data would be destroyed
when a dyno is killed due to inactivity.

Changing the `ShopifyApp::SessionRepository.storage` can simply be done by editing
`config/initializers/shopify_session_repository.rb` to use the correct model.

```ruby
ShopifyApp::SessionRepository.storage = 'Shop'
```

If you run the `shop_model` generator it will create the required code to use the generated Shop model as the SessionRepository and update the initializer.


Questions or problems?
----------------------
http://api.shopify.com <= Read up on the possible API calls!

http://ecommerce.shopify.com/c/shopify-apis-and-technology <= Ask questions!

http://docs.shopify.com/api/the-basics/getting-started <= Read the docs!
