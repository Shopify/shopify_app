# Script Tags

ShopifyApp can manage your app's [Script Tags](https://shopify.dev/docs/admin-api/graphql/reference/online-store/scripttag) for you by setting which script tags you require in the initializer.
> [!NOTE]
> Script tags should only be used for vintage themes that do not support app blocks.

## Configuration

```ruby
ShopifyApp.configure do |config|
  config.script_tags = [
    # Basic script tag
    {cache: true, src: 'https://example.com/fancy.js'},
    
    # Script tag with template_types for app block detection
    {
      cache: true, 
      src: 'https://example.com/product-script.js',
      template_types: ['product', 'collection']
    }
  ]
end
```

## Required Scopes
Both the `write_script_tags` and `read_themes` scopes are required.

For apps created with the Shopify CLI, set these scopes in your `shopify.app.toml` file:

```toml
[access_scopes]
# Learn more at https://shopify.dev/docs/apps/tools/cli/configuration#access_scopes
scopes = "write_products,write_script_tags,read_themes"
```

For older apps, you can set the scopes in the initializer:

```ruby
config.scope = 'write_products,write_script_tags,read_themes'
```

## How It Works

### Script Tag Creation

Script tags are created in the same way as [Webhooks](/docs/shopify_app/webhooks.md), with a background job which will create the required scripttags.

### App Block Detection

When you specify `template_types` for a script tag, ShopifyApp will check if the store's active theme supports app blocks for those template types. If any template type doesn't support app blocks, the script tags will be created as a fallback

This allows your app to automatically adapt to the store's theme capabilities, using app blocks when available and falling back to script tags when necessary.