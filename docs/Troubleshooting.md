# Troubleshooting Shopify App

#### Table of contents

[Generators](#generators)
  * [The `shopify_app:install` generator hangs](#the-shopifyappinstall-generator-hangs)

[App installation](#app-installation)
  * [My app won't install](#my-app-wont-install)

[JWT session tokens](#jwt-session-tokens)
  * [My app is still using cookies to authenticate](#my-app-is-still-using-cookies-to-authenticate)
  * [My app can't make requests to the Shopify API](#my-app-cant-make-requests-to-the-shopify-api)

## Generators

### The shopify_app:install generator hangs

Rails uses spring by default to speed up development. To run the generator, spring has to be stopped:

```sh
$ bundle exec spring stop
```

Run shopify_app generator again.

## App installation

### My app won't install

#### App installation fails with 'The page you’re looking for could not be found' if the app was installed before

This issue can occur when the session (the model you set as `ShopifyApp::SessionRepository.storage`) isn't deleted when the user uninstalls your app. A possible fix for this is listening to the `app/uninstalled` webhook and deleting the corresponding session in the webhook handler.

## JWT session tokens

### My app is still using cookies to authenticate

#### `shopify_app` gem version

Ensure the app is using shopify_app gem v13.x.x+. See [*Upgrading to `v13.0.0`*](/docs/Upgrading.md#upgrading-to-v1300).

#### `shopify_app` gem Rails configuration

Edit `config/initializer/shopify_app.rb` and ensure the following configurations are set:

```diff
+ config.embedded_app = true

+ config.allow_jwt_authentication = true
+ config.allow_cookie_authentication = false

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