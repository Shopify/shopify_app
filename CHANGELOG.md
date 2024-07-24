Unreleased
----------

22.3.0 (July 24, 2024)
----------
- Deprecate `ShopifyApp::JWTMiddleware`. And remove internal usage.  Any existing app code relying on decoded JWT contents set from `request.env` should instead include the `WithShopifyIdToken` concern and call its respective methods. [#1861](https://github.com/Shopify/shopify_app/pull/1861) [Migration Guide](/docs/Upgrading.md#v2300---removed-shopifyappjwtmiddleware)
- Handle scenario when invalid URI is passed to `sanitize_shop_domain` [#1852](https://github.com/Shopify/shopify_app/pull/1852)
- Remove references to old JS files during asset precompile [#1865](https://github.com/Shopify/shopify_app/pull/1865)
- Remove old translation keys for `enable_cookies_*`, `top_level_interaction_*` and `request_storage_access_*` [#1865](https://github.com/Shopify/shopify_app/pull/1865)
- Add invalid id token handling for `current_shopify_domain` method [#1868](https://github.com/Shopify/shopify_app/pull/1868)
- Keep original path and params when redirecting deep links to embed [#1869](https://github.com/Shopify/shopify_app/pull/1869)
- Fix managed install path for SPIN environments [#1877](https://github.com/Shopify/shopify_app/pull/1877)
- Migrate fullpage redirect to App Bridge CDN [#1870](https://github.com/Shopify/shopify_app/pull/1870)
- Improve embedded requests detection with `Sec-Fetch-Dest` header [#1873](https://github.com/Shopify/shopify_app/pull/1873)
- Fix bug where locale is not read from session if locale param is not present in app request [#1878](https://github.com/Shopify/shopify_app/pull/1878)

22.2.1 (May 6,2024)
----------
* Patch - Don't delete session on 401 errors during retry in `with_token_refetch` [#1844](https://github.com/Shopify/shopify_app/pull/1844)

22.2.0 (May 2,2024)
----------
* Add new zero redirect authorization strategy - `Token Exchange`.
  - This strategy replaces the existing OAuth flow for embedded apps and remove the redirects that were previously necessary to complete OAuth.
  See ["New embedded app authorization strategy (Token Exchange)"](/README.md/#new-embedded-app-authorization-strategy-token-exchange) for how to enable this feature.
  - Related PRs: [#1817](https://github.com/Shopify/shopify_app/pull/1817),
  [#1818](https://github.com/Shopify/shopify_app/pull/1818),
  [#1819](https://github.com/Shopify/shopify_app/pull/1819),
  [#1821](https://github.com/Shopify/shopify_app/pull/1821),
  [#1822](https://github.com/Shopify/shopify_app/pull/1822),
  [#1823](https://github.com/Shopify/shopify_app/pull/1823),
  [#1832](https://github.com/Shopify/shopify_app/pull/1832),
  [#1833](https://github.com/Shopify/shopify_app/pull/1833),
  [#1834](https://github.com/Shopify/shopify_app/pull/1834),
  [#1836](https://github.com/Shopify/shopify_app/pull/1836),
* Bumps `shopify_api` to `14.3.0` [1832](https://github.com/Shopify/shopify_app/pull/1832)
* Support `id_token` from URL param [1832](https://github.com/Shopify/shopify_app/pull/1832)
  * Extracted controller concern `WithShopifyIdToken`
      * This concern provides a method `shopify_id_token` to retrieve the Shopify Id token from either the authorization header or the URL param `id_token`.
  * `ShopifyApp::JWTMiddleware` supports retrieving session token from URL param `id_token`
  * `ShopifyApp::JWTMiddleware` returns early if the app is not embedded to avoid unnecessary JWT verification
  * `LoginProtection` now uses `WithShopifyIdToken` concern to retrieve the Shopify Id token, thus accepting the session token from the URL param `id_token`
* Marking `ShopifyApp::JWT` to be deprecated in version 23.0.0 [1832](https://github.com/Shopify/shopify_app/pull/1832), use `ShopifyAPI::Auth::JwtPayload` instead.
* Fix infinite redirect loop caused by handling errors from Billing API [1833](https://github.com/Shopify/shopify_app/pull/1833)

22.1.0 (April 9,2024)
----------
* Extracted class - `PostAuthenticateTasks` to handle post authenticate tasks. To learn more, see [post authenticate tasks](/docs/shopify_app/authentication.md#post-authenticate-tasks). [1819](https://github.com/Shopify/shopify_app/pull/1819)
* Bumps shopify_api dependency to 14.1.0 [1826](https://github.com/Shopify/shopify_app/pull/1826)

22.0.1 (March 12, 2024)
----------
* Bumps `shopify_api` to `14.0.1` [1813](https://github.com/Shopify/shopify_app/pull/1813)

22.00.0 (March 5, 2024)
----------

To migrate from a previous version, please see the [v22 migration guide](docs/Upgrading.md#upgrading-to-v2200).

* ⚠️ [Breaking] Bumps minimum supported Ruby version to 3.0. Bumps `shopify_api` to 14.0 [1801](https://github.com/Shopify/shopify_app/pull/1801)
* ⚠️ [Breaking] Removes deprecated controller concerns that were renamed in `v21.10.0`. [1805](https://github.com/Shopify/shopify_app/pull/1805)
* ⚠️ [Breaking] Removes deprecated `ScripttagManager`. We realize there was communication error in our logging where we logged future deprecation instead of our inteded removal. Since we have been logging that for 2 years we felt we'd move forward with the removal instead pushing this off until the next major release. [1806](https://github.com/Shopify/shopify_app/pull/1806)
* ⚠️ [Breaking] Removes ITP controller concern and `browser_sniffer` dependency.[1810](https://github.com/Shopify/shopify_app/pull/1810)
* ⚠️ [Breaking] Removes Marketing Extensions generator [1810](https://github.com/Shopify/shopify_app/pull/1810)
* ⚠️ [Breaking] Thows an error if a controller includes incompatible concerns (LoginProtection/EnsureInstalled) [1809](https://github.com/Shopify/shopify_app/pull/1809)
* ⚠️ [Breaking] No longer rescues non-shopify API errors during OAuth
  callback [1807](https://github.com/Shopify/shopify_app/pull/1807)
* Make type param for webhooks route optional. This will fix a bug with CLI initiated webhooks.[1786](https://github.com/Shopify/shopify_app/pull/1786)
* Fix redirecting to login when we catch a 401 response from Shopify, so that it can also handle cases where the app is already embedded when that happens.[1787](https://github.com/Shopify/shopify_app/pull/1787)
* Always register webhooks with offline sessions.[1788](https://github.com/Shopify/shopify_app/pull/1788)

21.10.0 (January 24, 2024)
----------
* Fix session deletion for users with customized session storage[#1773](https://github.com/Shopify/shopify_app/pull/1773)
* Add configuration flag `check_session_expiry_date` to trigger a re-auth when the (user) session is expired. The session expiry date must be stored and retrieved for this flag to be effective. When the `UserSessionStorageWithScopes` concern is used, a DB migration can be generated with `rails generate shopify_app:user_model --skip` and should be applied before enabling that flag[#1757](https://github.com/Shopify/shopify_app/pull/1757)

21.9.0 (January 16, 2024)
----------
* Fix `add_webhook` generator to create the webhook jobs under the correct directory[#1748](https://github.com/Shopify/shopify_app/pull/1748)
* Add support for metafield_namespaces in webhook registration [#1745](https://github.com/Shopify/shopify_app/pull/1745)
* Bumps `shopify_api` to latest version (13.4.0), adds support for 2024-01 API version [#1776](https://github.com/Shopify/shopify_app/pull/1776)

21.8.1 (December 6, 2023)
----------
* Bump `shopify_api` to 13.3.1 [1763](https://github.com/Shopify/shopify-api-ruby/blob/main/CHANGELOG.md#1331)

21.8.0 (Dec 1, 2023)
----------
* Bump `shopify_api` to include bugfix with mandatory webhooks + fixes for CI failures that prevented earlier release
* Fixes bug with `WebhooksManager#recreate_webhooks!` where we failed to register topics in the registry[#1743](https://github.com/Shopify/shopify_app/pull/1704)
* Allow embedded apps to provide a full URL to get redirected to, rather than defaulting to Shopify Admin [#1746](https://github.com/Shopify/shopify_app/pull/1746)

21.7.0 (Oct 12, 2023)
----------
* Fixes typo in webhook generator [#1704](https://github.com/Shopify/shopify_app/pull/1704)
* Fix registration of event_bridge and pub_sub webhooks [#1635](https://github.com/Shopify/shopify_app/pull/1635)
* Adds support for adding any number of trial days within `EnsureBilling` by adding the `trial_days` field to `BillingConfiguration`
* Updated AppBridge to 3.7.8 [#1680](https://github.com/Shopify/shopify_app/pull/1680)
* Support falling back to 2 letter language code locales [#1711](https://github.com/Shopify/shopify_app/pull/1711)
* Fix locale leaks across requests [#1711](https://github.com/Shopify/shopify_app/pull/1711)
* Fix bug in `InMemoryUserSessionStore#store`, this can now be used out of box. [#1716](https://github.com/Shopify/shopify_app/pull/1716)
* Adds support for 2023-10 API version [#1734](https://github.com/Shopify/shopify_app/pull/1734)

21.6.0 (July 11, 2023)
----------
* Adds support for toggling test charges within `EnsureBilling` by adding `test` field to `BillingConfiguration` and pulling in environment variable [#1688](https://github.com/Shopify/shopify_app/pull/1688)
* Adds support for 2023-07 API version [#1706](https://github.com/Shopify/shopify_app/pull/1706)

21.5.0 (May 18, 2023)
----------
* Support Unified Admin [#1658](https://github.com/Shopify/shopify_app/pull/1658)
* Set `access_scopes` column to string by default [#1636](https://github.com/Shopify/shopify_app/pull/1636)
* Fixes a bug with `EnsureBilling` causing infinite redirect in embedded apps [#1578](https://github.com/Shopify/shopify_app/pull/1578)
* Modifies SessionStorage#with_shopify_session to call a block with a supplied session instance [#1488](https://github.com/Shopify/shopify_app/pull/1488)
* Refactors `ShopifyApp::WebhhooksManager#recreate_webhooks!` to have a uniform webhook inventory that doesn't clash with the API library. Updates webhook generator to use supplied session. [#1686](https://github.com/Shopify/shopify_app/pull/1686)
* No longer use session repository from API library[#1689](https://github.com/Shopify/shopify_app/pull/1689)

21.4.1 (Feb 21, 2023)
----------
* Fixed bug where authentication redirect could still happen even though `reauth_on_access_scope_changes` is set to `false` [#1639](https://github.com/Shopify/shopify_app/pull/1639)

21.4.0 (Jan 5, 2023)
----------
* Updated shopify_api to 12.4.0 [#1633](https://github.com/Shopify/shopify_app/pull/1633)
* Removed Logged output for rescued JWT exceptions [#1610](https://github.com/Shopify/shopify_app/pull/1610)
* Fixes a bug with `ShopifyApp::WebhooksManager.destroy_webhooks` causing not passing session arguments to [unregister](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/webhooks/registry.rb#L99) method [#1569](https://github.com/Shopify/shopify_app/pull/1569)
* Validates shop's offline session token is still valid when using `EnsureInstalled`[#1612](https://github.com/Shopify/shopify_app/pull/1612)
* Allows use of multiple subdomains with myshopify_domain [#1620](https://github.com/Shopify/shopify_app/pull/1620)
* Added a `setup_shopify_session` test helper to stub a valid session

21.3.1 (Dec 12, 2022)
----------
* Fix bug with stores using the new unified admin that were falsely being flagged as phishing attempts [#1608](https://github.com/Shopify/shopify_app/pull/1608)

21.3.0 (Dec 9, 2022)
----------
* Move covered scopes check into user access strategy [#1600](https://github.com/Shopify/shopify_app/pull/1600)
* Add configuration option for user access strategy [#1599](https://github.com/Shopify/shopify_app/pull/1599)
* Fixes a bug with `EnsureAuthenticatedLinks` causing deep links to not work [#1549](https://github.com/Shopify/shopify_app/pull/1549)
* Ensure online token is properly used when using `current_shopify_session` [#1566](https://github.com/Shopify/shopify_app/pull/1566)
* Added debug logs, you can read more about logging [here](./docs/logging.md). [#1545](https://github.com/Shopify/shopify_app/pull/1545)
* Emit a deprecation notice for wrongly-rescued exceptions [#1530](https://github.com/Shopify/shopify_app/pull/1530)
* Log a deprecation warning for the use of incompatible controller concerns [#1560](https://github.com/Shopify/shopify_app/pull/1560)
* Fixes bug with expired sessions for embedded apps returning a 500 instead of 401 [#1580](https://github.com/Shopify/shopify_app/pull/1580)
* Generator properly handles uninstall [#1597](https://github.com/Shopify/shopify_app/pull/1597)
* Move ownership for session persistence from library to this gem [#1563](https://github.com/Shopify/shopify_app/pull/1563)
* Patch phishing vulnerability [#1605](https://github.com/Shopify/shopify_app/pull/1605)
* Remove `Itp` from `LoginProtection`. See the [upgrading docs](https://github.com/Shopify/shopify_app/blob/main/docs/Upgrading.md) for more information. [#1604](https://github.com/Shopify/shopify_app/pull/1604)

21.2.0 (Oct 25, 2022)
----------
* Pass access scopes on query string [#1540](https://github.com/Shopify/shopify_app/pull/1540)

21.1.1 (Oct 20, 2022)
----------
* Updates dependency to `shopify_api` to 12.2 to fix error with host_name argument.

21.1.0 (Oct 17, 2022)
----------
* Removes assumed `https` required to run locally. Support both `http` and `https` in backward compatible way. [#1518](https://github.com/Shopify/shopify_app/pull/1518)

21.0.0 (Oct 3, 2022)
----------
* Updating shopify_api gem to 12.0.0

20.2.0 (September 30, 2022)
----------
* Fixes a method signature error bug when raising `BillingError`.  [#1513](https://github.com/Shopify/shopify_app/pull/1513)
* Fixes bug with Rails 7 and import maps with Safari/Firefox on the HomeController#index view.  [#1506](https://github.com/Shopify/shopify_app/pull/1506)
* Refactors how default `domain_host` is populated in the CSP header added to responses in the `FrameAncestors` controller concern. [#1504](https://github.com/Shopify/shopify_app/pull/1504)
* Removes duplicate `;` added in CSP header. [#1500](https://github.com/Shopify/shopify_app/pull/1500)

* Fixed an issue where `ShopifyApp::UserSessionStorage` was causing an infinite OAuth loop when not checking scopes. [#1516](https://github.com/Shopify/shopify_app/pull/1516)
* Move all error classes created for this gem into `lib/shopify_app/errors.rb`. Constant names of errors nested by modules and classes have been removed to give a shorter namespace.

20.1.1 (September 2, 2022)
----------
* Fixed an issue where the `embedded_redirect_url` could lead to a redirect loop in server-side rendered (or production) apps. [#1497](https://github.com/Shopify/shopify_app/pull/1497)
* Fixes bug where webhooks were generated with addresses instead of the [path the Ruby API](https://github.com/Shopify/shopify-api-ruby/blob/7a08ae9d96a7a85abd0113dae4eb76398cba8c64/lib/shopify_api/webhooks/registrations/http.rb#L12) is expecting [#1474](https://github.com/Shopify/shopify_app/pull/1474). The breaking change that was accidentially already shipped was that `address` attribute for webhooks should be paths not addresses with `https://` and the host name. While the `address` attribute name will still work assuming the value is a path, this name is deprecated. Please configure webhooks with the `path` attribute name instead.
* Deduce webhook path from deprecated webhook address if initializer uses address attribute. This makes this attribute change a non-breaking change for those upgrading.

20.1.0 (August 22, 2022)
----------
* Set the appropriate CSP `frame-ancestor` directive in controllers using the `EmbeddedApp` concern. [#1474](https://github.com/Shopify/shopify_app/pull/1474)
* Allow [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/run-tunnel/trycloudflare/) hosts in `config/environments/development.rb`.
* Use [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/run-tunnel/trycloudflare/) as example tunnel in readme/docs.
* Change to optimize OAuth redirects to happen on the server side when possible.  Also, add an optional `.embedded_redirect_url` configuration parameter to enable customized App Bridge-supported redirect. [1483](https://github.com/Shopify/shopify_app/pull/1483)

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
* Create user session if one does not exist but was expected

14.2.0
------
* Revert "Replace redirect calls to use App Bridge redirect functionality"

14.1.0
------
* Replace redirect calls to use App Bridge redirect functionality

14.0.0
------
* Ruby 2.4 is no longer supported by this gem
* Bump gemspec ruby dependency to 2.5
* (Beta) Add `--with-session-token` flag to the Shopify App generator to create an app that is compatible with App Bridge Authentication

13.5.0
------
* Add `signal_access_token_required` helper method for apps to indicate access token has expired and that a new one is required

13.4.1
------
* Fix the version checks for the dependency on `shopify_api` to allow all of v9.X

13.4.0
------
* Skip CSRF protection if a valid signed JWT token is present as we trust Shopify to be the only source that can sign it securely. [#994](https://github.com/Shopify/shopify_app/pull/994)

13.3.0
------
* Added Payload Verification module [#992](https://github.com/Shopify/shopify_app/pull/992)
* Add concern to check for valid shop domains in the unauthenticated controller

13.2.0
------
* Get current shop domain from JWT header
* Validate that the omniauth data matches the JWT data
* Persist the token information to the session store

13.1.1
------
* Update browser_sniffer to 1.2.2

13.1.0
------
* Adds the shop URL as a parameter when redirecting after the callback
* Bump minimum Ruby version to 2.4
* Bug fixes

13.0.1
------
* Small addition to WebhookJob to return if the shop is nil #952
* Added Rubocop to the Repo #948
* Added a WebhookVerification test helper #950
* Fix for deprecation warning while loading session storage at startup
* Changes that will allow future JWT authentication

13.0.1
------
* fix for deprecation warning while loading session storage at startup

13.0.0
------
+ #887 Added concurrent user and shop session support (online/offline)
  BREAKING, please see README for migration notes.

12.0.7
------
* Remove check for API_KEY in config that was throwing errors during install #919

12.0.6
------
* Adds changelog information and README updates for 8.4.0 #916

12.0.5
------
* Updating shopify_api gem to 9.0.1

12.0.4
------
* Reverts reverted PR (#895) #897

12.0.3
------
* Moves samesite middleware higher in the stack #898
* Fix issue where not redirecting user to granted storage page casues infinite loop #900

12.0.2
------
* Reverts "Fix for return_to in safari after enable_cookies/granted_storage_access" introduced in 12.0.1

12.0.1
------
* disable samesite cookie middleware in tests
* middleware compatibility for ruby 2.3
* samesite cookie fixes for javascript libraries
* change generators to add AppBridge instead of EASDK
* Fix for return_to in safari after enable_cookies/granted_storage_access

12.0.0
-----
* Updating shopify_api gem to 9.0.0

11.7.1
-----
* Fix to allow SessionStorage to be flexible on what model names that the are used for storing shop and user data

11.7.0
-----
* Move ExtensionVerificationController from engine to app controllers, as being in the engine makes ActionController::Base get loaded before app initiates [#855](https://github.com/Shopify/shopify_app/pull/855)
* Add back per-user token support (added in 11.5.0, reverted in 11.5.1)
  * If you have an override on the `self.store(auth_session)` method on your `SessionRepository` model, the method signature must be changed as according to this [change](https://github.com/Shopify/shopify_app/pull/856/files#diff-deaed2b262ec885f4e36de05621e41eaR18)

11.6.0
-----
* Enable SameSite=None; Secure by default on all cookies for embedded apps [#851](https://github.com/Shopify/shopify_app/pull/851)
  * Ensures compatibility of embedded apps with upcoming Chrome version 80 changes to cookie behaviour
  * Configurable via `ShopifyApp.configuration.enable_same_site_none` (default true for embedded apps)

11.5.1
-----
* Revert per-user token support temporarily

11.5.0
-----
* Modularizes durable session storage
* Introduces per-user token support and user session management

11.4.0
-----
* Remove `dotenv-rails` dependency. [#835](https://github.com/Shopify/shopify_app/pull/835)

11.3.2
-----
* Fix hosts generator in Rails 5 [#823](https://github.com/Shopify/shopify_app/pull/823)

11.3.1
-----
* Bump browser_sniffer version to 1.1.3 [#824](https://github.com/Shopify/shopify_app/pull/824)

11.3.0
-----
* Update assets to be compatible with Rails 6 [#808](https://github.com/Shopify/shopify_app/pull/808)

11.2.1
-----
* Adds ngrok whitelist in development [#802](https://github.com/Shopify/shopify_app/pull/802)

11.2.0
-----

* Bump omniauth-shopify-oauth2 gem to v2.2.0

11.1.0
-----

* Add Webmock and Pry as development dependencies
* Update install generator to leverage updates to ShopifyAPI::ApiVersion add in v8.0.0 of the shopify_api gem [#790](https://github.com/Shopify/shopify_app/pull/790)


11.0.2
-----

* Lock shopify_api gem dependency to `~> 7.0` from `>= 7.0.0`.
* Remove flakey JS Tests
* bump sqlite3 development dependency to `~>1.4` from `~> 1.3.6`. [#789](https://github.com/Shopify/shopify_app/pull/789)

11.0.1
-----

* Add dotenv-rails gem to install generator, so apps fetch credentials from `.env` by default: [#776](https://github.com/Shopify/shopify_app/pull/776)

11.0.0
-----

* Rename `login_url` method to `login_url_with_optional_shop` to avoid ambiguity with Rails' route helper method of the
  same name (see [#585](https://github.com/Shopify/shopify_app/pull/585)).

10.0.0
-----

* Make sure OAuth-related redirects return user to originally requested URL once authenticated
* Add/update translations
* Update README to clarify nested routes
* Remove example app. Users should instead use the generators to scaffold an example app.
* Bump required Rails version to `> 5.2.1` to ensure `5.2.1.1` or greater is used. This ensures two things:
  * Apps are not vulnerable to [CVE-2018-16476](https://nvd.nist.gov/vuln/detail/CVE-2018-16476)
  * Webhook payloads, from Shopify for API version 2019-07, which are processed in ActiveJob background jobs (the
    default behaviour of shopify_app's WebhooksController) are compatible, due to how ActiveJob versions prior to
    5.2.1.1 process GlobalIDs encoded as string in job parameters. This prevents the
    [exceptions reported previously](https://github.com/Shopify/shopify_app/issues/600).

9.0.4
-----

* Fix returning to a deep link after authentication [#746](https://github.com/Shopify/shopify_app/pull/746)

9.0.3
-----

* Add `meta viewport` tags to fix mobile responsive problems
* Remove outdated, extraneous `yarn.lock` file (and rely on existing `package-lock.json` instead)
* Move inline js to a js asset file
* Minor documentation corrections

9.0.2
-----

* Update browser_sniffer to fix unnecessary ITP flows in Shopify Mobile
* Add additional languages to translation.yml
* Minor documentation corrections

9.0.1
-----

* Minor documentation corrections
* Handle `Webhook.all` returning `nil` and raising on `index_by`


9.0.0
-----

* Breaking change: Api version support added see [migration guide](README.md#upgrading-from-86-to-900)

8.6.1
-----

* Locked `shopify_api` gem to version < 7.0.  7.0 will have breaking changes that are incompatable with `shopify_app`

* Session storage validation for shopify_domain is now set to `case_sensitive: false`.

8.6.0
-----

* Added an `Authenticated` concern to allow gem users to inherit from a custom `AuthenticatedController` instead of
  `ShopifyApp::AuthenticatedController`

8.5.1
-----

* Fixed a typo in RotateShopifyTokenJob

8.5.0
-----
Added support for rotating Shopify access tokens:

* Added a generator shopify_app:rotate_shopify_token_job for generating the job to perform token rotation
* Extend Shopify app configuration to support a new and old secret token
* Extended webhook validation code to support validating against new and old secret tokens
* See the README for more details: https://github.com/Shopify/shopify_app#rotateshopifytokenjob

8.4.2
-----
* Clear stale user session during auth callback

8.4.1
-----
* Update README and Releasing.md
* Allow user agent to not be set
* Remove legacy EASDK examples
* Add .ruby-version file
* Clean up omniauth setup and fix examples
* Fix infinite redirect loops if users have disabled 3rd party cookies in their browser

8.4.0
----
* Fix embedded app session management in Safari 12.1
  * Note that with this change we have extracted the callback action in its own controller. If you are relying on it, see the README for more details: https://github.com/Shopify/shopify_app#callback
* Shop names passed to OAuth are no longer case sensitive

8.3.2
----
* Removes `read_orders` from the default scopes provided upon app generation

8.3.1
----
* Adds the ability to customize the login URL through the initializer

8.3.0
----
* Fix embedded app session management in Safari 12
* Add support for translation platform

8.2.6
----
* Sanitize the shop query param to include `.myshopify.com` if no domain was provided

8.2.5
----
* fix iframe headers on session controller

8.2.4
-----
* Add CSRF protection through `protect_from_forgery with: :exception` on `ShopifyApp::AuthenticatedController`

8.2.3
-----
* Send head :forbidden instead of :unauthorized when AppProxyVerification fails

8.2.2
-----
* Changes how the ESDK concern allows iframes. Fixes an issue with the first request for some people

8.2.1
-----
* Bugfix: Don't logout shops from `login_again_if_different_shop` when Rails
  params for a 'Shop' model are passed in [[#477]](https://github.com/Shopify/shopify_app/pull/477)

8.2.0
-----
Known bug: Shop logged out when submitting a form for 'Shop' objects, fixed in 8.2.1 [[See #480 for details]](https://github.com/Shopify/shopify_app/issues/480)

* Add `webhook_jobs_namespace` config option. [[#463]](https://github.com/Shopify/shopify_app/pull/463)
* Updates login page styles to match the [Polaris](https://polaris.shopify.com/) design system. [[#474]](https://github.com/Shopify/shopify_app/pull/474)

8.1.0
-----
Known bug: Shop logged out when submitting a form for 'Shop' objects, fixed in 8.2.1 [[See #480 for details]](https://github.com/Shopify/shopify_app/issues/480)

* Add support for per_user_authentication
* Pass the shop param in the session for authentication instead of a url param (prevents csrf). If you are upgrading from an older version of the gem you will need to update your omniauth.rb initializer file. Check the example app for what it what it should look like.

8.0.0
-----
Known bug: Shop logged out when submitting a form for 'Shop' objects, fixed in 8.2.1 [[See #480 for details]](https://github.com/Shopify/shopify_app/issues/480)

* Removed the `shopify_session_repository` initializer. The SessionRepository is now configured through the main ShopifyApp configuration object and the generated initializer
* Moved InMemorySessionStore into the ShopifyApp namespace
* Remove ShopifySession concern. This module made the code internal to this engine harder to follow and we want to discourage over-writing the auth code now that we have generic hooks for all extra tasks during install.
* Changed engine controllers to subclass ActionController::Base to avoid any possible conflict with the parent application
* Removed the `ShopifyApp::Shop` concern and added its methods to `ShopifyApp::SessionStorage`. To update for this change just remove this concern anywhere it is being used in your application.
* Add `ShopifyApp::EmbeddedApp` controller concern which handles setting the required headers for the ESDK. Previously this was done by injecting configuration into applicaton.rb which affects the entire app.
* Add webhooks to generated home controller. This should help new users debug issues.

7.4.0
-----
Known bug: Shop logged out when submitting a form for 'Shop' objects, fixed in 8.2.1 [[See #480 for details]](https://github.com/Shopify/shopify_app/issues/480)

* Add an after_authenticate job which will be run once the shop is authenticated. [[#431]](https://github.com/Shopify/shopify_app/pull/432)

7.3.0
-----
Known bug: Shop logged out when submitting a form for 'Shop' objects, fixed in 8.2.1 [[See #480 for details]](https://github.com/Shopify/shopify_app/issues/480)

* Bump required omniauth-shopify-oauth2 version to 1.2.0.
* Always expect params[:shop] to be a string.

7.2.11
-----
* Remove 'Logged in' flash message [[#425]](https://github.com/Shopify/shopify_app/pull/425)

7.2.10
-----
* Fix an issue with the create_shops generator template
  [[#423]](https://github.com/Shopify/shopify_app/pull/423)

7.2.9
-----
* Remove support for Rails 4
  [[#417]](https://github.com/Shopify/shopify_app/pull/417)

7.2.8
-----
* Add i18n locale param support
  [[#409]](https://github.com/Shopify/shopify_app/pull/409)


7.2.7
-----
* Require `shopify_app` `>= 4.3.2`. This version relaxes the ruby version requirement from `>= 2.3.0` to `>= 2.0`
* Rails 5: ActionDispatch::Reloader#to_prepare is deprecated
  [[#404]](https://github.com/Shopify/shopify_app/pull/404)

7.2.6
-----
* Update LoginProtection#fullpage_redirect_to to get shopify domain from session
  [[#401]](https://github.com/Shopify/shopify_app/pull/401)

7.2.5
-----
* Update LoginProtection.redirection_javascript to work with absolute URLS
  [[#389]](https://github.com/Shopify/shopify_app/pull/389)

7.2.4
-----
* Fix redirect issue by sanitizing shop name on sessions#new

7.2.3
-----
* Use postMessage to redirect parent iframe during authentication [[#366]](https://github.com/Shopify/shopify_app/pull/366)
* Add support for dynamically generating scripttag URLs
* Bug-fix: Update scripttags_manager_job
* Bug-fix: `--application_name` and `--scope` generates proper Configuration even when options supplied to them contain whitespaces.

7.2.0
-----
* Disable application layout rendering for the `/login` page

7.1.1
-----
* Lower required Ruby version to 2.2.2 to better match up with Rails 5.0

7.1.0
-----
* Update login page copy
* Add application_name configuration option
* Add new optional App Proxy Controller Generator to the Engine. Refer README for details.
* Include ShopifyApp::LoginProtection in Authenticated and Session Controller directly instead of Application Controller.
* Loosen ShopifyAPI dependency requirements to `>= 4.2.2` and allow ShopifyAPI 4.3.0 and above.
* Move application.js to inside HEAD in Embedded App Template.
* Add ability to override the ActiveJob queue names in initializer file.

7.0.11
------
* Pass configured resources (like webhooks or scripttags) into the job rather than reading the config again. This allows for dynamically setting ShopifyApp config in a web request and having the job handle it correctly. This change does not affect the usage of webhooks or scripttags

7.0.10
------
* Loosen Rails dependency requirements to `>= 4.2.6` and allow Rails 5.0
* Add support for App Proxies

7.0.9
-----

* Remove http-equiv meta tag as it causes OAuth issues in Chrome

7.0.5
-----

* Remove obtrusive “Continue” text in redirects

7.0.4
-----

* Bump required shopify_api version to 4.x.

7.0.3
-----

* Bump required Rails version to `>= 4.2.6` since we are now using `ActiveSupport::SecurityUtils:Module`

7.0.2
-----

* Fix CSRF redirect issue

7.0.1
-----

* add support to i18n for flash messages (English and Spanish).

7.0.0
-----

* rename WebhooksController module to WebhookVerification
* added a WebhooksController which automatically delegates to jobs
* moved all engine controllers under the ShopifyApp namespace
* rename SessionsController module to SessionsConcern
* more robust redirects, with valid HTML in HTTP response bodies
* `ShopifyApp::Controller` has been removed. You’ll need to replace all includes of `ShopifyApp::Controller` with `ShopifyApp::LoginProtection`
* adds add_webhook generator to make it easier to add new webhooks to your app
* update the install generator to use standard rails generate arguments, usage has changed from `-api_key=your_key` to `--api_key your_key`
* remove the redirect uri - this is done automatically inside omniauth now

6.4.2
-----

* Update minimum required rails version to 4.2 to include active job

6.4.0
-----

* More semantic and accessible markup in the sessions/new, embedded_app, and product
  index views.
* Moved all JavaScript to load at the bottom of the page instead of the head, for
  page loading better performance.

6.3.0
-----

* Move SessionStorage from a generated class to a re-usable module. To
  migrate to the new module, delete the old generated SessionStorage class
  in the models directory and include the SessionStorage module in your Shop model.
* Adds a WebhooksManager class and allows you to configure what webhooks your app
  needs. The rest is taken care of by ShopifyApp provided you set up a backgroud queue
  with ActiveJob
* Adds a WebhooksController module which can be included to handle the boiler plate code
  for a controller receiving webhooks from Shopify

6.2.1
-----

* add callback url to omniauth provider
* add default redirect_uri

6.2.0
-----

* Return an HTTP 401 for XHRs that aren't logged in

6.1.3
-----
* add redirect_uri which is now required
* fix login again with different shop

6.0.0
-----
* Re-written as a proper rails engine
* New modular generators
* generates embedded apps by default
* can bootstrap your app with a standard shop table and model
* code now lives as concerns in the engine which are included in your controllers
  feel free to override anything you need in your app

Historical
----------
* re-styled with Twitter Bootstrap css framework and updated docs [warren]
* Require shopify_api gem via proper railtie setup [willem]
* Don't require shopify.yml when using environment variables [cody]
* Renamed instances of current_shop to shop_session to maintain logic
* Replace old LoginController with a RESTful SessionsController
