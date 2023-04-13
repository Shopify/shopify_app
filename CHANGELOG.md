Unreleased
----------

* Set the appropriate CSP `frame-ancestor` directive in controllers using the `EmbeddedApp` concern. [#1474](https://github.com/Shopify/shopify_app/pull/1474)
* Allow [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/run-tunnel/trycloudflare/) hosts in `config/environments/development.rb`.
* Use [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/run-tunnel/trycloudflare/) as example tunnel in readme/docs.
* Modifies SessionStorage#with_shopify_session to call a block with a supplied session instance [#1488]

20.0.2 (July 7, 2022)
----------

* Bump [Shopify API](https://github.com/Shopify/shopify-api-ruby) to version 11.0.1. It includes [these updates](https://github.com/Shopify/shopify-api-ruby/blob/main/CHANGELOG.md#version-1101). Fix an issue where HMAC signature verification would fail in OAuth flows during API key rotation.

20.0.1 (July 6, 2022)
----------

* Accept extra keyword arguments to WebhooksManagerJob to ease upgrade path from v18 or older (https://github.com/Shopify/shopify_app/pull/1466)

20.0.0 (July 4, 2022)
----------

* Bump [Shopify API](https://github.com/Shopify/shopify-api-ruby) to version 11.0.0. It includes [these updates](https://github.com/Shopify/shopify-api-ruby/blob/main/CHANGELOG.md#version-1100). The breaking change relates to the removal of API version `2021-07` support.
* Internal update, adding App Bridge 3 for redirect (only). [#1458](https://github.com/Shopify/shopify_app/pull/1458)

19.1.0 (June 20, 2022)
----------

* Add the `login_callback_url` config to allow overwriting that route as well, and mount the engine routes based on the configurations. [#1445](https://github.com/Shopify/shopify_app/pull/1445)
* Add special headers when returning 401s from LoginProtection. [#1450](https://github.com/Shopify/shopify_app/pull/1450)
* Add a new `billing` configuration which takes in a `ShopifyApp::BillingConfiguration` object and checks for payment on controllers with `Authenticated`. [#1455](https://github.com/Shopify/shopify_app/pull/1455)

19.0.2 (April 27, 2022)
----------

* Fix regression in apps using online tokens. [#1413](https://github.com/Shopify/shopify_app/pull/1413)
* Bump [Shopify API](https://github.com/Shopify/shopify-api-ruby) to version 10.0.3. It includes [these fixes](https://github.com/Shopify/shopify-api-ruby/blob/main/CHANGELOG.md#version-1003).

19.0.1 (April 11, 2022)
----------
* Bump Shopify API (https://github.com/Shopify/shopify-api-ruby) to version 10.0.2. This update includes patch fixes since the initial v10 release.

19.0.0 (April 6, 2022)
----------
* Use v10 of the Shopify API (https://github.com/Shopify/shopify-api-ruby). This update requires changes to an app - please refer to the [migration guide](https://github.com/Shopify/shopify_app/blob/main/docs/Upgrading.md) for details.
BREAKING, please see migration notes.

18.1.2 (Mar 3, 2022)
----------
* Use the App Bridge 2.0 redirect when attempting to break out of an iframe. This happens when an app is installed, requires new access scopes, or re-authentication because the login session is expired. [#1376](https://github.com/Shopify/shopify_app/pull/1376)

18.1.1 (Feb 2, 2022)
----------
* Fix bug causing `unsafe-inline` CSP violation. [#1362](https://github.com/Shopify/shopify_app/pull/1362)

18.1.0 (Jan 28, 2022)
----------
* Support Rails 7 [#1354](https://github.com/Shopify/shopify_app/pull/1354)
* Fix webhooks handling in Ruby 3 [#1342](https://github.com/Shopify/shopify_app/pull/1342)
* Update to Ruby 3 and drop support to Ruby 2.5 [#1359](https://github.com/Shopify/shopify_app/pull/1359)

18.0.4 (Jan 27, 2022)
----------
* Use App Bridge client for redirect [#1247](https://github.com/Shopify/shopify_app/pull/1247)
  * Replaces deprecated EASDK with App Bridge when redirecting out of an embedded iframe.

18.0.3 (Jan 7, 2022)
----------
* Change regexp to match standard ngrok URLs. [#1311](https://github.com/Shopify/shopify_app/pull/1311)
* Make `EnsureAuthenticatedLinks` compatible with AppBridge 2.0. [#1277](https://github.com/Shopify/shopify_app/pull/1277)
  * Includes the `host` parameter when redirecting to the splash page in an unauthenticated state.

18.0.2 (Jun 15, 2021)
----------
* Added careers link to readme. [#1274](https://github.com/Shopify/shopify_app/pull/1274)

18.0.1 (May 7, 2021)
----------
* Fix bug causing OAuth flow to fail due to CSP violation. [#1265](https://github.com/Shopify/shopify_app/pull/1265)

18.0.0 (May 3, 2021)
----------
* Support OmniAuth 2.x
  * If your app has custom OmniAuth configuration, please refer to the [OmniAuth 2.0 upgrade guide](https://github.com/omniauth/omniauth/wiki/Upgrading-to-2.0).
* Support App Bridge version 2.x in the Embedded App layout. [#1241](https://github.com/Shopify/shopify_app/pull/1241)

17.2.1 (April 1, 2021)
----------
* Bug fix: Lock the CDN App Bridge version to `v1.X.Y` in the Embedded App layout [#1238](https://github.com/Shopify/shopify_app/pull/1238)
  * App Bridge `v2.0` is a non-backwards compatible release
  * A future major shopify_app gem release will support only App Bridge `v2.0`

17.2.0 (April 1, 2021)
----------
* Support Rails `v6.1` [#1221](https://github.com/Shopify/shopify_app/pull/1221)
  * Check out [Upgrading to `v17.2.0`](/docs/Upgrading.md#upgrading-to-v1720) in the Upgrading.md guide for the changes needed to support Rails `v6.1`

17.1.1 (March 12, 2021)
----------
* Fix issues with mocking OmniAuth callback controller tests [#1210](https://github.com/Shopify/shopify_app/pull/1210)

17.1.0 (March 5, 2021)
----------
* Create OmniAuthConfiguration object to build future OmniAuth strategies [#1190](https://github.com/Shopify/shopify_app/pull/1190)
* Added access scopes to Shop and User models, added checks to handle scope changes [#1192](https://github.com/Shopify/shopify_app/pull/1192) [#1197](https://github.com/Shopify/shopify_app/pull/1197)

17.0.5 (January 27, 2021)
----------
* Fix omniauth strategy not being set correctly for apps using session tokens [#1164](https://github.com/Shopify/shopify_app/pull/1164)

17.0.4 (January 25, 2021)
----------
* Redirect user to login page if shopify domain is not found in the `EnsureAuthenticatedLinks` concern [#1158](https://github.com/Shopify/shopify_app/pull/1158)

17.0.3 (January 22, 2021)
----------
* Amend fix for #1144 to raise on missing API keys only when running the server [#1155](https://github.com/Shopify/shopify_app/pull/1155)

17.0.2 (January 20, 2021)
------
* Fix failing script tags and webhooks installs after completing OAuth [#1151](https://github.com/Shopify/shopify_app/pull/1151)

17.0.1 (January 18, 2021)
------
* Don't attempt to read Shopify environment variables when the generators are running, since they may not be present yet [#1144](https://github.com/Shopify/shopify_app/pull/1144)

17.0.0 (January 13, 2021)
------
* Rails 6.1 is not yet supported [#1134](https://github.com/Shopify/shopify_app/pull/1134)

16.1.0
------
* Use Session Token auth strategy by default for new embedded apps [#1111](https://github.com/Shopify/shopify_app/pull/1111)
* Create optional `EnsureAuthenticatedLinks` concern to authenticate deep links using Turbolinks [#1118](https://github.com/Shopify/shopify_app/pull/1118)

16.0.0
------
* Update all `html.erb` and `css` files to correspond with updated store admin design language [#1102](https://github.com/Shopify/shopify_app/pull/1102)

15.0.1
------
* Allow JWT session token `sub` field to be parsed as a string [#1103](https://github.com/Shopify/shopify_app/pull/1103)

15.0.0
------
* Change `X-Shopify-API-Request-Failure-Unauthorized` HTTP header value from boolean to string

14.4.4
------
* Patch to not log params in ShopifyApp jobs [#1086](https://github.com/Shopify/shopify_app/pull/1086)

14.4.3
------
* Fix to ensure post authenticate jobs are run after callback requests [#1079](https://github.com/Shopify/shopify_app/pull/1079)

14.4.2
------
* Add debug logs in sessions controller

14.4.1
------
* Add debug logs for investigating authentication issues

14.4.0
------
* Replace script tags for ITP screens with data attributes

14.3.0
------
* Create user session if one do
