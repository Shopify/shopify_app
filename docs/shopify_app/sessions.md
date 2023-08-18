# Sessions

Sessions are used to make contextual API calls for either a shop (offline session) or a user (online session). This gem has ownership of session persistence.

#### Table of contents

- [Sessions](#sessions-2)
  - [Types of session tokens](#types-of-session-tokens) - Shop (offline) v.s. User (online)
  - [Session token storage](#session-token-storage)
      * [Shop (offline) token storage](#shop-(offline)-token-storage)
      * [User (online) token storage](#user-(online)-token-storage)
  * [`ShopifyApp::SessionRepository`](#shopifyappsessionrepository)
  * [Loading Sessions](#loading-sessions)
- [Access scopes](#access-scopes)
  * [`ShopifyApp::ShopSessionStorageWithScopes`](#shopifyappshopsessionstoragewithscopes)
  * [``ShopifyApp::UserSessionStorageWithScopes``](#shopifyappusersessionstoragewithscopes)
- [Migrating from shop-based to user-based token strategy](#migrating-from-shop-based-to-user-based-token-strategy)

## Sessions
#### Types of session tokens
- **Shop** ([offline access](https://shopify.dev/docs/apps/auth/oauth/access-modes#offline-access))
  - Access token is linked to the store
  - Meant for long-term access to a store, where no user interaction is involved
  - Ideal for background jobs or maintenance work
- **User** ([online access](https://shopify.dev/docs/apps/auth/oauth/access-modes#online-access))
  - Access token is linked to an individual user on a store
  - Meant to be used when a user is interacting with your app through the web

⚠️  [Read more about Online vs. Offline access here](https://shopify.dev/apps/auth/oauth/access-modes).

#### Session token storage
##### Shop (offline) token storage
⚠️ All apps must have a shop session storage, if you started from the [Ruby App Template](https://github.com/Shopify/shopify-app-template-ruby), it's already configured to have a Shop model by default.

1. If you don't already have a repository to store the access tokens, run the following generator to create a shop model to store the access tokens:

```sh
rails generate shopify_app:shop_model
```

2. Configure your `/initializers/shopify_app.rb` to enable shop session token persistance:

```ruby
config.shop_session_repository = 'Shop'
```

##### User (online) token storage
If your app has user interactions and would like to control permission based on individual users, you need to configure a User token storage to persist unique tokens for each user.

[Shop (offline) tokens must still be maintained](#shop-(offline)-token-storage).

1. Run the following generator to create a user model to store the individual based access tokens
```sh
rails generate shopify_app:user_model
```

2. Configure your `/initializers/shopify_app.rb` to enable user session token persistance:

```ruby
config.user_session_repository = 'User'
```

The current Shopify user will be stored in the rails session at `session[:shopify_user]`

### Customized Session Storage - ShopifyApp::SessionRepository

`ShopifyApp::SessionRepository` allows you as a developer to define how your sessions are stored and retrieved for shops. The `SessionRepository` is configured in the `config/initializers/shopify_app.rb` file and can be set to any object that implements `self.store(auth_session, *args)` which stores the session and returns a unique identifier and `self.retrieve(id)` which returns a `ShopifyAPI::Session` for the passed id. These methods are already implemented as part of the `ShopifyApp::SessionStorage` concern but can be overridden for custom implementation.

### Loading Sessions
By using the appropriate controller concern, sessions are loaded for you.  Note -- these controller concerns cannot both be included in the same controller.

#### Shop Sessions - `EnsureInstalled`
`EnsureInstalled` controller concern will load a shop session with the `installed_shop_session` helper. If a shop session is not found, meaning the app wasn't installed for this shop, the request will be redirected to be installed.

This controller concern should NOT be used if you don't need your app to make calls on behalf of a user.

#### User Sessions - `EnsureHasSession`
 `EnsureHasSession` controller concern will load a user session via `current_shopify_session`. As part of loading this session, this concern will also ensure that the user session has the appropriate scopes needed for the application. If the user isn't found or has fewer permitted scopes than are required, they will be prompted to authorize the application.

This controller concern should be used if you don't need your app to make calls on behalf of a user. With that in mind, there are a few other embedded concerns that are mixed in to ensure that embedding, CSRF, localization, and billing allow the action for the user.

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
