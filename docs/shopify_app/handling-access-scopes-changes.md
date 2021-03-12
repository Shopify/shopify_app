# Handling changes in access scopes
The Shopify App gem provides handling changes to scopes for both shop/offline and user/online tokens. To enable your app to login via OAuth on scope changes, you can set the following configuration flag in your `config/initializers/shopify_app.rb`:
```ruby
config.reauth_on_access_scope_changes = true
```

## ShopAccessScopesVerification
The `ShopifyApp::ShopAccessScopesVerification` concern helps merchants grant new access scopes requested by the app. The concern compares the current access scopes granted by the shop and compares them with the scopes requested by the app. If there is a mismatch in configuration, the merchant is redirected to login via OAuth and grant the net new scopes.

To activate the `ShopAccessScopesVerification` for a controller add `include ShopifyApp::ShopAccessScopesVerification`:
```ruby
class HomeController < AuthenticatedController
  include ShopifyApp::ShopAccessScopesVerification
```
