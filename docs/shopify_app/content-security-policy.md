# Content Security Policy Header

Shopify App [handles Rails' configuration](https://edgeguides.rubyonrails.org/security.html#content-security-policy-header) for [Content-Security-Policy Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) when the `ShopifyApp::FrameAncestors` controller concern is included in controllers. This is typically done by including the [`ShopifyApp::Authenticated`](https://github.com/Shopify/shopify_app/blob/ed41165ca9598d2c9d514487365192f22b5eb096/app/controllers/concerns/shopify_app/authenticated.rb) controller concern rather than directly including it.

## Frame Ancestors

For actions that include the `ShopifyApp::FrameAncestors` controller concern, the following hosts are added to the `frame-ancestors` directive as [per the store requirements](https://shopify.dev/apps/store/security/iframe-protection#embedded-apps):

1. [`current_shopify_domain`](https://github.com/Shopify/shopify_app/blob/ed41165ca9598d2c9d514487365192f22b5eb096/app/controllers/concerns/shopify_app/require_known_shop.rb#L13) || `"*.myshopify.com"` if current shopify domain isn't present
2. "https://admin.shopify.com"

## Strict Content Security Policy

If you enable a strict Content Security Policy in your application, you'll need to explicitly allow Shopify's App Bridge script. The gem provides a helper method to make this easy.

### Without Strict CSP (Default)

By default, Shopify app templates have CSP **disabled** (commented out in `config/initializers/content_security_policy.rb`). In this configuration:
- Inline scripts work (including Vite HMR for development)
- App Bridge loads without any configuration
- No `script-src` directive is set

### With Strict CSP

If you enable a strict CSP by uncommenting and configuring `content_security_policy.rb`, you must:

1. **Handle inline scripts** - Strict CSP blocks inline scripts. You can:
   - Use `unsafe-inline` in development (for Vite HMR)
   - Use nonces or hashes in production
   - Move inline scripts to external files

2. **Allow App Bridge script** - Add the App Bridge script source using the provided helper:

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https

    # For development: allow inline scripts for Vite HMR
    if Rails.env.development?
      policy.script_src :self, :unsafe_inline
    else
      policy.script_src :self
    end

    # Add Shopify App Bridge script source
    ShopifyApp.add_csp_directives(policy)
  end
end
```

The `ShopifyApp.add_csp_directives(policy)` helper method:
- Adds `https://cdn.shopify.com/shopifycloud/app-bridge.js` to your `script-src` directive
- Preserves your existing `script-src` configuration
- Prevents duplicate URLs if called multiple times
- Is a no-op if you don't configure CSP
