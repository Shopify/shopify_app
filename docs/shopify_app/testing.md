# Testing

#### Table of content

[Using test helpers inside your application](#using-test-helpers-inside-your-application)

[Testing an embedded app outside the Shopify admin](#testing-an-embedded-app-outside-the-shopify-admin)

## Using test helpers inside your application

A test helper that will allow you to test `ShopifyApp::WebhookVerification` in the controller from your app, to use this test, you need to `require` it directly inside your app `test/controllers/webhook_verification_test.rb`.

```ruby
    require 'test_helper'
    require 'action_controller'
    require 'action_controller/base'
    require 'shopify_app/test_helpers/webhook_verification_helper'
```

Or you can require in your `test/test_helper.rb`.

```ruby
  ENV['RAILS_ENV'] ||= 'test'
  require_relative '../config/environment'
  require 'rails/test_help'
  require 'byebug'
  require 'shopify_app/test_helpers/all'
```

With `lib/shopify_app/test_helpers/all'` more tests can be added and will only need to be required in once in your library.

## Testing an embedded app outside the Shopify admin

By default, loading your embedded app will redirect to the Shopify admin, with the app view loaded in an `iframe`. If you need to load your app outside of the Shopify admin (e.g., for performance testing), you can change `forceRedirect: true` to `false` in `ShopifyApp.init` block in the `embedded_app` view. To keep the redirect on in production but off in your `development` and `test` environments, you can use:

```javascript
forceRedirect: <%= Rails.env.development? || Rails.env.test? ? 'false' : 'true' %>
```