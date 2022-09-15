# Content Security Policy Header

Shopify App [handles Rails' configuration](https://edgeguides.rubyonrails.org/security.html#content-security-policy-header) for [Content-Security-Policy Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) when the `ShopifyApp::FrameAncestors` controller concern is included in controllers. This is tyipcally done by including the [`ShopifyApp::Authenticated`](https://github.com/Shopify/shopify_app/blob/ed41165ca9598d2c9d514487365192f22b5eb096/app/controllers/concerns/shopify_app/authenticated.rb) controller concern rather that directly including it.

## Included Domains

For actions that include the `ShopifyApp::FrameAncestors` controller concern, the following hosts are added to the Content-Security-Policy header as [per the store requirements](https://shopify.dev/apps/store/security/iframe-protection#embedded-apps):

1. [`current_shopify_domain`](https://github.com/Shopify/shopify_app/blob/ed41165ca9598d2c9d514487365192f22b5eb096/app/controllers/concerns/shopify_app/require_known_shop.rb#L13) || `"*.myshopify.com"` if current shopify domain isn't present
2. "https://admin.shopify.com"
