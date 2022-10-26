# Troubleshooting Shopify App

#### Table of contents

[Generators](#generators)
  * [The `shopify_app:install` generator hangs](#the-shopify_appinstall-generator-hangs)g

[Rails](#rails)
  * [Known issues with Rails `v6.1`](#known-issues-with-rails-v61)

[App installation](#app-installation)
  * [My app won't install](#my-app-wont-install)
  * [My app keeps redirecting to login](#my-app-keeps-redirecting-to-login)
  * [My app returns 401 during oauth](#my-app-returns-401-during-oauth)

[JWT session tokens](#jwt-session-tokens)
  * [My app is still using cookies to authenticate](#my-app-is-still-using-cookies-to-authenticate)
  * [My app can't make requests to the Shopify API](#my-app-cant-make-requests-to-the-shopify-api)
  * [I'm stuck in a redirect loop after OAuth](#im-stuck-in-a-redirect-loop-after-oauth)

## Generators

### The shopify_app:install generator hangs

Rails uses spring by default to speed up development. To run the generator, spring has to be stopped:

```sh
bundle exec spring stop
```

Run shopify_app generator again.

## Rails

### Known issues with Rails `v6.1`

If you recently upgraded your application's `Rails::Application` configuration to load the default configuration for Rails `v6.1`, then you will need to update the following `cookies_same_site_protection` ActionDispatch configuration.

```diff
# config/application.rb

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module AppName
  class Application < Rails::Application
+    config.load_defaults 6.1

+    config.action_dispatch.cookies_same_site_protection = :none
    ...
  end
end
```

As of Rails `v6.1`, the same-site cookie protection setting defaults  to `Lax`. This does not allow an embedded app to make cross-domain requests in the Shopify Admin.

Alternatively, you can upgrade to [`v17.2.0` of the shopify_app gem](/docs/Upgrading.md#upgrading-to-v1720).

## App installation

### My app won't install

#### App installation fails with 'The page you’re looking for could not be found' if the app was installed before

This issue can occur when the session (the model you set as `ShopifyApp::SessionRepository.storage`) isn't deleted when the user uninstalls your app. A possible fix for this is listening to the `app/uninstalled` webhook and deleting the corresponding session in the webhook handler.

### My app returns 401 during oauth

If your local dev env uses the `cookie_store` session storage strategy, you may encounter 401 errors during oauth due to a race condition between asset requests and `/auth/shopify`. You should be able to work around for local testing by using a different browser or session storage strategy.  [Read more about the status of this issue](https://github.com/Shopify/shopify_app/issues/1269).

## JWT session tokens

### My app is still using cookies to authenticate

#### `shopify_app` gem version

Ensure the app is using shopify_app gem v13.x.x+. See [*Upgrading to `v13.0.0`*](/docs/Upgrading.md#upgrading-to-v1300).

#### `shopify_app` gem Rails configuration

Edit `config/initializer/shopify_app.rb` and ensure the following configurations are set:

```diff
+ config.embedded_app = true

# This line should already exist if you're using shopify_app gem 13.x.x+
+ config.shop_session_repository = 'Shop'
```

#### Inspect server logs

If you have checked the configurations above, and the app is still using cookies, then it is possible that the `shopify_app` gem defaulted to relying on cookies. This would happen when your browser allows third-party cookies and a session token was not successfully found as part of your request.

In this case, check the server logs to see if the session token was invalid:

```los
[ShopifyApp::JWT] Failed to validate JWT: [JWT::<Error>] <Failure message>
```

*Example*

```
[ShopifyApp::JWT] Failed to validate JWT: [JWT::ImmatureSignature] Signature nbf has not been reached
```

**Note:** In a local development environment, you may want to temporarily update your `Gemfile` to point to a local instance of the `shopify_app` library instad of an installed gem. This will enable you to use a debugging tool like `byebug` to debug the library.

```diff
- gem 'shopify_app', '~> 14.2'
+ gem 'shopify_app', path: '/path/to/shopify_app'
```

### My app can't make requests to the Shopify API

> **Note:** Session tokens cannot be used to make authenticated requests to the Shopify API. Learn more about authenticating your backend requests to Shopify APIs at [Shopify API authentication](https://shopify.dev/concepts/about-apis/authentication).

#### The Shopify API returns `401 Unauthorized`

If your app uses [user-based token storage](/docs/shopify_app/session-repository.md#user-based-token-storage), then your app is configured to use **online** access tokens (see [API access modes](https://shopify.dev/concepts/about-apis/authentication#api-access-modes) to learn the difference between "online" and "offline" access tokens ). Unlike offline access tokens, online access tokens expire daily and cannot be used to make authenticated requests to the Shopify API once they expire.

Converting your app to use session tokens means that your app will most likely not go through the OAuth flow as often as it did when relying on cookie sessions. Since the online access tokens stored in your app's database are refreshed during OAuth, this may cause your app's user session repository to use expired online access tokens.

If the Shopify API  returns `401 Unauthorized`, handle this error on your app by redirecting the user to your login path to start the OAuth flow. As a result, your app will be given a new online access token for the current user.

> **Note:** The following are examples to common app configurations. Your specific use-case may differ.

##### Example solution

Add the following line to your app's unauthorized response handler:

```diff
+ redirect_to(ShopifyApp.configuration.login_url, shop: current_shopify_domain)
```

_Example:_ If your embedded app cannot handle server-side XHR redirects, then configure your app's unauthorized response handler to set a response header:

```
X-Shopify-API-Request-Failure-Unauthorized: true
```

Then, use the [Shopify App Bridge Redirect](https://shopify.dev/tools/app-bridge/actions/navigation/redirect) action to redirect your app frontend to the app login URL if this header is set.

### I'm stuck in a redirect loop after OAuth

In previous versions of `ShopifyApp::Authenticated` controller concern, App Bridge embedded apps were able to include the `Authenticated` controller concern in the `HomeController` and other embedded controllers. This is no longer supported due to browsers blocking 3rd party cookies to increase privacy. App Bridge 3 is needed to handle all embedded sessions.

For more details on how to handle embeded sessions, refer to [the session token documentation](https://shopify.dev/apps/auth/oauth/session-tokens).

### `redirect_uri is not whitelisted`

* Ensure you have set the `HOST` environment variable to match your host's URL, e.g. `http://localhost:3000` or `https://my-host-name.trycloudflare.com`.
* Update the app's URL and whitelisted URLs in App Setup on https://partners.shopify.com

### `This app can’t load due to an issue with browser cookies`

This can be caused by an infinite redirect due to a coding error
To investigate the cause, you can add a breakpoint or logging to the `rescue` clause of `ShopifyApp::CallbackController`.

One possible cause is that XHR requests, the `Authenticated` concern should be used, rather than `RequireKnownShop`.
