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
$ rails generate shopify_app --api_key a366cbafaccebd2f615aebdfc932fa1c --secret 8750306a895b3dbc7f4136c2ae2ea293
$ git add .
$ git commit -m 'generated shopify app'
```

If you forget to set your keys or redirect uri above you will find them in the shopify_app initializer at: `/config/initializers/.`

We recommend adding a gem or utilizing ENV variables to handle your keys before releasing your app.

6. Deploy
---------
```sh
$ git push heroku
$ heroku run rake db:migrate
```

7. Install the App!
-------------------
`https://<name>.herokuapp.com/`
