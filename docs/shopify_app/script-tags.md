# ScriptTags

#### Table of contents

[Manage ScriptTags using the Shopify App initializer](#manage-scripttags-using-the-shopify-app-initializer)

## Manage ScriptTags using the Shopify App initializer

As with webhooks, ShopifyApp can manage your app's [ScriptTags](https://shopify-dev-staging.shopifycloud.com/docs/admin-api/graphql/reference/online-store/scripttag) for you by setting which scripttags you require in the initializer:

```ruby
ShopifyApp.configure do |config|
  config.scripttags = [
    {event:'onload', src: 'https://example.com/fancy.js'},
    {event:'onload', src: ->(domain) { dynamic_tag_url(domain) } }
  ]
end
```

You also need to have write_script_tags permission in the config scope in order to add script tags automatically:

```ruby
 config.scope = '... , write_script_tags'
```

Scripttags are created in the same way as the [Webhooks](/docs/shopify_app/webhooks.md), with a background job which will create the required scripttags.

If `src` responds to `call` its return value will be used as the scripttag's source. It will be called on scripttag creation and deletion.
