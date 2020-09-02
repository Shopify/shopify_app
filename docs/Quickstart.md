Quickstart
==========

Get started building and deploying a new Shopify App to Heroku in just a few minutes.
This guide assumes you have Ruby, Rails and PostgreSQL installed on your computer already; if you haven't done that already start with [this guide.](https://guides.rubyonrails.org/v5.0/getting_started.html#installing-rails)

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

CLI:
```sh
$ heroku create name
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

Run this command to add the `shopify_app` Gem to your app:

```sh
$ bundle add shopify_app
```

**Note:** we recommend using the latest version of Shopify Gem. Check the [Git tags](https://github.com/Shopify/shopify_app/tags) to see the latest release version and then add it to your Gemfile e.g `gem 'shopify_app', '~> 7.0.0'`

5. Run the ShopifyApp generator
-------------------------------

Generate the code for your app by running these commands: 

```sh
# Use the keys from your app you created in the partners area
$ rails generate shopify_app
$ git add .
$ git commit -m 'generated shopify app'
```

Your API key and secret are read from environment variables. Refer to the main
README for further details on how to set this up.

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

Install the app onto your new development store using the Partner Dashboard. Log in to your account, visit the apps page, click the app you created earlier, and looking for the `Test your app` instructions where you can select a store to install your app on.

![Installing an app on the partners dashboard dropdown](/docs/install-on-dev-shop.png)

### OR

![Installing an app on the partners dashboard card](/docs/test-your-app.png)

8. Great work! 
-------------------

You're done creating your first app on Shopify. Keep going and learn more by [diving into our full documentation](https://help.shopify.com/en/api/getting-started), or join our [community of developers.](https://community.shopify.com/c/Shopify-Apps/bd-p/shopify-apps)
