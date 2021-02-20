# Engine

#### Table of content

[Customize the app login URL](#customize-the-app-login-url)

[Mount the Shopify App engine at nested routes](#mount-the-shopify-app-engine-at-nested-routes)

[Verify HTTP requests sent via an app proxy](#verify-http-requests-sent-via-an-app-proxy)
  * [Recommended usage of `ShopifyApp::AppProxyVerification`](#recommended-usage-of-shopifyappappproxyverification)

## Customize the app login URL

While you can customize the login view by creating a `/app/views/shopify_app/sessions/new.html.erb` file, you may also want to customize the URL entirely. You can modify your `shopify_app.rb` initializer to provide a custom `login_url` e.g.:

```ruby
ShopifyApp.configure do |config|
  config.login_url = 'https://my.domain.com/nested/login'
end
```

## Mount the Shopify App engine at nested routes

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

## Verify HTTP requests sent via an app proxy

See [`ShopifyApp::AppProxyVerification`](/lib/shopify_app/controller_concerns/app_proxy_verification.rb).

The engine provides a mixin for verifying incoming HTTP requests sent via an App Proxy. Any controller that `include`s `ShopifyApp::AppProxyVerification` will verify that each request has a valid `signature` query parameter that is calculated using the other query parameters and the app's shared secret.

### Recommended usage of `ShopifyApp::AppProxyVerification`

The App Proxy Controller Generator automatically adds the mixin to the generated app_proxy_controller.rb
Additional controllers for resources within the App_Proxy namespace, will need to include the mixin like so:

```ruby
# app/controllers/app_proxy/reviews_controller.rb
class ReviewsController < ApplicationController
  include ShopifyApp::AppProxyVerification
  # ...
end
```

Create your app proxy URL in the [Shopify Partners dashboard](https://partners.shopify.com/organizations), making sure to point it to `https://your_app_website.com/app_proxy`.

![Creating an App Proxy](/images/app-proxy-screenshot.png)
