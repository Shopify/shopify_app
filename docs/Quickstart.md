Quickstart
==========

Get started building and deploying a new Shopify App to Heroku in just a few minutes. This guide assumes you have Ruby/Rails installed on your computer already; if you haven't done that already start with [this guide.](https://guides.rubyonrails.org/v5.0/getting_started.html#installing-rails)

1. New Rails App (with postgres)
--------------------------------

To create a new Rails app and use this generator, open your terminal and run the following commands:

```sh
$ rails new test-app --database=postgresql
$ cd test-app
$ git init
$ git add .
$ git commit -m 'new rails app'
```

2. Create a new Heroku app
--------------------------

The next step is to create a new Heroku app to host your application. If you haven't got a Heroku account yet, create a free account [here](https://www.heroku.com/). 

Head to the Heroku dashboard and create a new app, or run the following commands with the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli#download-and-install) installed, substituting `name` for the name of your own app:

cli:
```sh
$ heroku create name
$ heroku git:remote -a name
```

Once you have created an app on Heroku, we need to let Git know where the Heroku server is so we can deploy to it later. Copy the app's name from your Heroku dashboard and substitute `appname.git` with the name you chose earlier:

web:
```sh
# https://dashboard.heroku.com/new
$ git remote add heroku git@heroku.com:appname.git
```

3. Create a new App in the Shopify Partner dashboard
-----------------------------------------
* Create a Shopify app in the [Partners dashboard](https://partner.shopify.com). For this tutorial, you can choose either a public or custom app, but you can [learn about App Types here.](https://help.shopify.com/en/manual/apps/app-types)
[https://app.shopify.com/services/partners/api_clients](https://app.shopify.com/services/partners/api_clients)
* Set the callback url to `https://<appname>.herokuapp.com/`
* Choose an embedded app
* Set the app's `redirect_uri` to `https://<appname>.herokuapp.com/auth/shopify/callback`


4. Add ShopifyApp to Gemfile
----------------------------

Run these commands to add the `shopify_app` Gem to your app:

```sh
$ echo "gem 'shopify_app'" >> Gemfile
$ bundle install
```

**Note:** we recommend using the latest version of Shopify Gem. Check the [Git tags](https://github.com/Shopify/shopify_app/tags) to see the latest release version and then add it to your Gemfile e.g `gem 'shopify_app', '~> 7.0.0'`

5. Run the ShopifyApp generator
-------------------------------

Generate the code for your app by running these commands: 

```sh
# Use the keys from your app you created in the partners area
$ rails generate shopify_app --api_key <shopify_api_key> --secret <shopify_api_secret>
$ git add .
$ git commit -m 'generated shopify app'
```

If you forget to set your keys or redirect uri above, you will find them in the shopify_app initializer at: `/config/initializers/shopify_app.rb`.

We recommend adding a gem or utilizing environment variables (ENV) to handle your keys before releasing your app. [Learn more about using environment variables.](https://www.honeybadger.io/blog/ruby-guide-environment-variables/)

6. Deploy your app
---------

Once you've generated your app, push it into your Heroku environment to see it up and running:
```sh
$ git push heroku
$ heroku run rake db:migrate
```

7. Install the App!
-------------------

Ensure you have created a [development store](https://help.shopify.com/en/api/getting-started/making-your-first-request#create-a-development-store) using the Shopify Partner Dashboard. If you don't already have one, [create one by following these instructions](https://help.shopify.com/en/api/getting-started/making-your-first-request#create-a-development-store).

##### Note: The following step will cause your store to become `transfer-disabled.` Read more about store transfer and why it's important [here](https://help.shopify.com/en/api/guides/store-transfers#transfer-disabled-stores). This is an irreversible change, so be sure you don't plan to transfer this store to a merchant.

Install the app onto your new development store using the Partner Dashboard by heading to the apps page, clicking your app, and looking for the `Test your app` instructions where you can select a store to install your app on.

![Installing an app on the partners dashboard dropdown](/docs/install-on-dev-shop.png)

### OR

![Installing an app on the partners dashboard card](/docs/test-your-app.png)

