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

The next step is to create a new heroku app. Pull up your heroku dashboard and make a new app!

cli:
```sh
$ heroku create name
$ heroku git:remote -a name
```

now we need to let git know where the remote server is so we'll be able to deploy later

web:
```sh
# https://dashboard.heroku.com/new
$ git remote add heroku git@heroku.com:appinfive.git
```

3. Create a new App in the partners area
-----------------------------------------
[https://app.shopify.com/services/partners/api_clients](https://app.shopify.com/services/partners/api_clients)
* set the callback url to `https://<name>.herokuapp.com/`
* choose an embedded app
* set the redirect_uri to `https://<name>.herokuapp.com/auth/shopify/callback`


4. Add ShopifyApp to gemfile
----------------------------
```sh
$ echo "gem 'shopify_app'" >> Gemfile
$ bundle install
```

Note - its recommended to use the latest released version. Check the git tags to see the latest release and then add it to your Gemfile e.g `gem 'shopify_app', '~> 7.0.0'`

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

6. Deploy
---------
```sh
$ git push heroku
$ heroku run rake db:migrate
```

7. Install the App!
-------------------
1. Ensure you have a dev store created, if you don't already have one, [create one](https://help.shopify.com/en/api/getting-started/making-your-first-request#create-a-development-store).

##### Important Note: Installing the app on a development store in the following step will convert the store to be [transfer-disabled](https://help.shopify.com/en/api/guides/store-transfers#transfer-disabled-stores). This is an irreversible change.

2. Install the app using your Partners Dashboard in the Apps area.

![Installing an App on a dev store using partners dashboard](/docs/install-on-dev-shop.png)
