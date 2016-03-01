Quickstart
==========

Build and deploy a new Shopify App to Heroku in minutes

1. New Rails App (with postgres)
--------------------------------

```
rails new test-app --database=postgresql
cd test-app
git init
git add .
git commit -m 'new rails app'
```

2. Create a new Heroku app
--------------------------

The next step is to create a new heroku app. Pull up your heroku dashboard and make a new app!

cli:
```
heroku new
git remote -v
git remote set-url heroku git@heroku.com:<name>.git
  ```

now we need to let git know where the remote server is so we'll be able to deploy later

web:
```
https://dashboard.heroku.com/new
git remote add heroku git@heroku.com:appinfive.git
```

3. Create a new App in the partners area
-----------------------------------------
[https://app.shopify.com/services/partners/api_clients](https://app.shopify.com/services/partners/api_clients)
* set the callback url to `https://<name>.herokuapp.com/`
* choose an embedded app
* set the redirect_uri to `https://<name>.herokuapp.com/auth/shopify/callback`


4. Add ShopifyApp to gemfile
----------------------------
```
vim Gemfile
  add
    gem 'shopify_app', '~> 6.0.6'

bundle install
```

5. Run the ShopifyApp generator
-------------------------------
```
use the keys from your app in the partners area
rails generate shopify_app -api_key=a366cbafaccebd2f615aebdfc932fa1c -secret=8750306a895b3dbc7f4136c2ae2ea293 -redirect_uri=https://<name>.herokuapp.com/auth/shopify/callback
git add .
git commit -m 'generated shopify app'
```

6. Changing redirect URI in Omniauth
------------------------------------
```
Go to your omniauth config file found at /config/initializers/omniauth and make sure to set the redirect URI.
Set it to your APPNAME.herokuapp.com/auth/shopify/callback adress, as it will default to localhost:3000 on app creation.
```

7. Deploy
---------
```
git push heroku
heroku run rake db:migrate
```

8. Install the App!
-------------------
`https://<name>.herokuapp.com/`
