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
