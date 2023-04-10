# Handling changes in access scopes
## Updating the list of scopes the app requests

Your app specifies the [access scopes](https://shopify.dev/api/usage/access-scopes) it requires in the Shopify App initializer, located at`config/initializers/shopify_app.rb`. To modify this list, update the comma-delimited configuration option:

```ruby
config.scope = "read_products,write_discounts"
```

## Requesting new scopes from merchants

The Shopify App gem will automatically request new scopes from merchants for both shop/offline and user/online tokens. To enable your app to reauth via OAuth on scope changes, you can set the following configuration flag in your `config/initializers/shopify_app.rb`:
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
