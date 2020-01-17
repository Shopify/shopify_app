Quickstart
==========

Build and deploy a new Shopify App to Heroku in minutes

1. New Rails App (with postgres)
--------------------------------

```sh
$ rails new test-app --database=postgresql
$ cd test-app
$ git init
$ git add .
$ git commit -m 'new rails app'
```

2. Create a new Heroku app
--------------------------

The next step is to create a new Heroku app. Pull up your Heroku dashboard and make a new app!

cli:
```sh
$ heroku create name
$ heroku git:remote -a name
```

Now we need to let git know where the remote server is so we'll be able to deploy later

web:
```sh
# https://dashboard.heroku.com/new
$ git remote add heroku git@heroku.com:appinfive.git
```

3. Create a new App in the Shopify Partner dashboard
-----------------------------------------
* Create a Shopify app in the [Partners dashboard](https://partner.shopify.com). For this tutorial, you can choose either a public or custom app, but you can [learn about App Types here.](https://help.shopify.com/en/manual/apps/app-types)
[https://app.shopify.com/services/partners/api_clients](https://app.shopify.com/services/partners/api_clients)
* Set the callback url to `https://<name>.herokuapp.com/`
* Choose an embedded app
* Set the app's `redirect_uri` to `https://<name>.herokuapp.com/auth/shopify/callback`


4. Add ShopifyApp to gemfile
----------------------------
```sh
$ echo "gem 'shopify_app'" >> Gemfile
$ bundle install
```

Note - it's recommended to use the latest version of the Shopify Gem. Check the Git tags to see the latest release and then add it to your Gemfile e.g `gem 'shopify_app', '~> 7.0.0'`

5. Run the ShopifyApp generator
-------------------------------
```sh
# use the keys from your app in the partners area
$ rails generate shopify_app --api_key <shopify_api_key> --secret <shopify_api_secret>
$ git add .
$ git commit -m 'generated shopify app'
```

If you forget to set your keys or redirect uri above, you will find them in the shopify_app initializer at: `/config/initializers/shopify_app.rb`.

We recommend adding a gem or utilizing ENV variables to handle your keys before releasing your app.

6. Deploy your app
---------
```sh
$ git push heroku
$ heroku run rake db:migrate
```

7. Install the App!
-------------------
 Ensure you have created a development store on the Shopify Partner Dashboard. If you don't already have one, [create one by following these instructions](https://help.shopify.com/en/api/getting-started/making-your-first-request#create-a-development-store).

##### Note: The following step will cause your store to become `transfer-disabled.` Read more about store transfer and why it's important [here](https://help.shopify.com/en/api/guides/store-transfers#transfer-disabled-stores). This is an irreversible change, so be sure you don't plan to transfer this store to a merchant.

Install the app using the Partner Dashboard in the Apps area.

![Installing an app on the partners dashboard dropdown](/docs/install-on-dev-shop.png)

### OR

![Installing an app on the partners dashboard card](/docs/test-your-app.png)

