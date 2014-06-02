# Shopify App

Shopify application generator for Rails 3.1 and Rails 4.0

## Description

This gem makes it easy to get a Rails 3.1 or Rails 4.0 app up and running with the Shopify API.

The generator creates a basic SessionsController for authenticating with your shop and a HomeController which displays basic information about your products, orders and articles.

*Note: It's recommended to use this on a new Rails project, so that the generator won't overwrite/delete some of your files.*

## Installation

``` sh
# Create a new rails app
$ rails new my_shopify_app
$ cd my_shopify_app

# Add the gem shopify_app to your Gemfile
$ echo "gem 'shopify_app'" >> Gemfile
$ bundle install
```

## Usage

``` sh
$ rails generate shopify_app your_app_api_key your_app_secret
```

If you don't have an API key yet, create a Shopify Partner account at http://shopify.com/partners and create an app. You can also create test shops once you're logged in as a partner.

When you create your app in the Shopify Partner Account, set the Application Callback URL to

	http://localhost:3000

You can also create a private application that only works for your shop by visiting https://YOUR-SHOP.myshopify.com/admin/apps/private.

### Example

``` sh
$ rails generate shopify_app edffbb1bb793e2750686e6f4647a384a fed5bb18hde3e2750686e6f4647a781a
```

This will create a LoginController and a HomeController with their own views.

## Configuring Shopify App

It's possible to set your API key and secret key from different sources:

* `SHOPIFY_APP_API_KEY` and `SHOPIFY_APP_SECRET` environment variables
* Configuration in a Rails `<environment>.rb` config file

``` ruby
config.shopify.api_key = 'your api key'
config.shopify.secret = 'your secret'
```

* Configuration loaded from `<environment>` key in `shopify_app.yml`

``` yaml
development:
  api_key: your api key
  secret: your secret
```

* Configuration loaded from common key in `shopify_app.yml`

``` yaml
common:
  api_key: your api key
  secret: your secret
```

## Set up your ShopifySessionRepository.store

`ShopifySessionRepository` allows you as a developer to define how your sessions are retrieved and
stored for a shop. This can simply be your `Shop` model that stores the API Token and shop name. If
you are using ActiveRecord, then all you need to implement is `self.store(shopify_session)` that
converts that data into a record on disk.

By default you will have an in memory store but it really won't work on multi-server environments since
they won't be sharing the static data that would be required in case your user gets directed to a
different server by your load balancer.

Changing the `ShopifySessionRepository.store` can simply be done by editings
`config/initializers/shopify_session_repository.rb` to use the correct model.

## Set your required API permissions

Before making API requests, your application must state which API permissions it requires from the shop it's installed in. These requested permissions will be listed on the screen the merchant sees when approving your app to be installed in their shop.

Start by reviewing the documentation on API permission scopes: http://docs.shopify.com/api/tutorials/oauth

When you know which ones your app will need, add a scope line to the `config/initializers/omniauth.rb` file.

### Example

Make this change to request write access to products and read access to orders:

``` ruby
Rails.application.config.middleware.use OmniAuth::Builder do
    provider :shopify, 
       ShopifyApp.configuration.api_key, 
       ShopifyApp.configuration.secret,
       :scope => "write_products,read_orders",
       :setup => lambda {|env| 
                   params = Rack::Utils.parse_query(env['QUERY_STRING'])
                   site_url = "https://#{params['shop']}"
                   env['omniauth.strategy'].options[:client_options][:site] = site_url
                 }
end
```

*Note that you can change your API permission scopes on the fly, but the merchant will have to approve each change and your computed API password will change.*

## After running the generator

First, start your application:

``` sh
$ rails server
```

Now visit http://localhost:3000 and install your application in a Shopify store. Even if Rails tells you to visit your app at http://0.0.0.0:3000, go to http://localhost:3000.

After your application has been given whatever API permissions you requested by the shop, you're ready to start experimenting with the Shopify API.

## Rails 3.0 (as in before 3.1) Support

Rails 3.0 (as in before the big changes in 3.1) is supported on a branch of our github repo: https://github.com/Shopify/shopify_app/tree/rails_3.0_support

## Common problems

If you are getting the following error:

```
Faraday::Error::ConnectionFailed error when accessing app.
```
    
It probably means that the CA certificate on your computer is out of date. A simple solution on the Mac is to install XCode.

If you are getting the following error:

```
ActiveResource::ForbiddenAccess in HomeController#index
Failed.  Response code = 403.  Response message = Forbidden.
```

It means that you have not set appropriate permissions in your `config/initializers/omniauth.rb` file for what you are trying to do in your HomeController#index action. Example: you set your permissions to 'write_content' because that's what your app will do, but your HomeController#index still has that default code generated by shopify_app which attempts to read products and orders, neither being covered by the 'write_content' scope.

## Questions or problems?

http://api.shopify.com <= Read up on the possible API calls!

http://ecommerce.shopify.com/c/shopify-apis-and-technology <= Ask questions!

http://docs.shopify.com/api/the-basics/getting-started <= Read the docs!
