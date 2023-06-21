# Sessions

Sessions are used to make contextual API calls for either a shop (offline session) or a user (online session). This gem has ownership of session persistence.

#### Table of contents

[Sessions](#sessions)
  * [Shop-based token storage](#shop-based-token-storage)
  * [User-based token storage](#user-based-token-storage)
  * [`ShopifyApp::SessionRepository`](#shopifyappsessionrepository)
  * [Loading Sessions](#loading-sessions)

[Access scopes](#access-scopes)
  * [`ShopifyApp::ShopSessionStorageWithScopes`](#shopifyappshopsessionstoragewithscopes)
  * [``ShopifyApp::UserSessionStorageWithScopes``](#shopifyappusersessionstoragewithscopes)

[Migrating from shop-based to user-based token strategy](#migrating-from-shop-based-to-user-based-token-strategy)

### Shop-based token storage (offline token)

Storing tokens on the store model means that any user login associated with the store will have equal access levels to whatever the original user granted the app.
```sh
rails generate shopify_app:shop_model
```
This will generate a shop model which will be the storage for the tokens necessary for authentication. To enable session persistance, you'll need to configure your `/initializers/shopify_app.rb` accordingly:

```ruby
config.shop_session_repository = 'Shop'
```

### User-based token storage (online token)

A more granular control over the level of access per user on an app might be necessary, to which the shop-based token strategy is not sufficient. Shopify supports a user-based token storage strategy where a unique token to each user can be managed. Shop tokens must still be maintained if you are running background jobs so that you can make use of them when necessary.
```sh
rails generate shopify_app:shop_model
rails generate shopify_app:user_model
```
This will generate a shop model and user model, which will be the storage for the tokens necessary for authentication.

This will generate a user and shop model which will be the storage for the tokens necessary for authentication. To enable session persistance, you'll need to configure your `/initializers/shopify_app.rb` accordingly:

```ruby
config.shop_session_repository = 'Shop'
config.user_session_repository = 'User'
```

The current Shopify user will be stored in the rails session at `session[:shopify_user]`

Read more about Online vs. Offline access [here](https://shopify.dev/apps/auth/oauth/access-modes).

### Customized Session Storage - ShopifyApp::SessionRepository

`ShopifyApp::SessionRepository` allows you as a developer to define how your sessions are stored and retrieved for shops. The `SessionRepository` is configured in the `config/initializers/shopify_app.rb` file and can be set to any object that implements `self.store(auth_session, *args)` which stores the session and returns a unique identifier and `self.retrieve(id)` which returns a `ShopifyAPI::Session` for the passed id. These methods are already implemented as part of the `ShopifyApp::SessionStorage` concern but can be overridden for custom implementation.

### Loading Sessions
By using the appropriate controller concern, sessions are loaded for you. `RequireKnownShop` controller concern will load a shop session with the `installed_shop_session` helper. `EnsureHasSession` controller concern will load a user session via `current_shopify_session`. Note -- these controller concerns cannot both be included in the same controller.

## Access scopes

If you want to customize how access scopes are stored for shops and users, you can implement the `access_scopes` getters and setters in the models that include `ShopifyApp::ShopSessionStorageWithScopes` and `ShopifyApp::UserSessionStorageWithScopes` as shown:

### `ShopifyApp::ShopSessionStorageWithScopes`
```ruby
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  def access_scopes=(scopes)
    # Store access scopes
  end
  def access_scopes
    # Find access scopes
  end
end
```

### `ShopifyApp::UserSessionStorageWithScopes`
```ruby
class User < ActiveRecord::Base
  include ShopifyApp::UserSessionStorageWithScopes

  def access_scopes=(scopes)
    # Store access scopes
  end
  def access_scopes
    # Find access scopes
  end
end
```

## Migrating from shop-based to user-based token strategy

1. Run the `user_model` generator as mentioned above.
2. Ensure that both your `Shop` model and `User` model includes the necessary concerns `ShopifyApp::ShopSessionStorage` and `ShopifyApp::UserSessionStorage`.
3. Make changes to the `shopify_app.rb` initializer file as shown below:
```ruby
config.shop_session_repository = {YOUR_SHOP_MODEL_CLASS}
config.user_session_repository = {YOUR_USER_MODEL_CLASS}
```
