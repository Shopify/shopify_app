# Webhooks

#### Table of contents

[Manage webhooks using `ShopifyApp::WebhooksManager`](#manage-webhooks-using-shopifyappwebhooksmanager)

## Manage webhooks using `ShopifyApp::WebhooksManager`

See [`ShopifyApp::WebhooksManager`](/lib/shopify_app/managers/webhooks_manager.rb)
ShopifyApp can manage your app's webhooks for you if you set which webhooks you require in the initializer:

```ruby
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'carts/update', address: 'https://example.com/webhooks/carts_update'}
  ]
end
```

When the [OAuth callback](/docs/shopify_app/authentication.md#oauth-callback) is completed successfully, ShopifyApp will queue a background job which will ensure all the specified webhooks exist for that shop. Because this runs on every OAuth callback, it means your app will always have the webhooks it needs even if the user uninstalls and re-installs the app.

ShopifyApp also provides a [WebhooksController](/app/controllers/shopify_app/webhooks_controller.rb) that receives webhooks and queues a job based on the received topic. For example, if you register the webhook from above, then all you need to do is create a job called `CartsUpdateJob`. The job will be queued with 2 params: `shop_domain` and `webhook` (which is the webhook body).

If you would like to namespace your jobs, you may set `webhook_jobs_namespace` in the config. For example, if your app handles webhooks from other ecommerce applications as well, and you want Shopify cart update webhooks to be processed by a job living in `jobs/shopify/webhooks/carts_update_job.rb` rather than `jobs/carts_update_job.rb`):

```ruby
ShopifyApp.configure do |config|
  config.webhook_jobs_namespace = 'shopify/webhooks'
end
```

If you are only interested in particular fields, you can optionally filter the data sent by Shopify by specifying the `fields` parameter in `config/webhooks`. Note that you will still receive a webhook request from Shopify every time the resource is updated, but only the specified fields will be sent.

```ruby
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'products/update', address: 'https://example.com/webhooks/products_update', fields: ['title', 'vendor']}
  ]
end
```

If you'd rather implement your own controller then you'll want to use the [`ShopifyApp::WebhookVerification`](/lib/shopify_app/controller_concerns/webhook_verification.rb) module to verify your webhooks, example:

```ruby
class CustomWebhooksController < ApplicationController
  include ShopifyApp::WebhookVerification

  def carts_update
    params.permit!
    SomeJob.perform_later(shop_domain: shop_domain, webhook: webhook_params.to_h)
    head :no_content
  end

  private

  def webhook_params
    params.except(:controller, :action, :type)
  end
end
```

The module skips the `verify_authenticity_token` before_action and adds an action to verify that the webhook came from Shopify. You can now add a post route to your application, pointing to the controller and action to accept the webhook data from Shopify.

The WebhooksManager uses ActiveJob. If ActiveJob is not configured then by default Rails will run the jobs inline. However, it is highly recommended to configure a proper background processing queue like Sidekiq or Resque in production.

ShopifyApp can create webhooks for you using the `add_webhook` generator. This will add the new webhook to your config and create the required job class for you.

```
rails g shopify_app:add_webhook -t carts/update -a https://example.com/webhooks/carts_update
```

Where `-t` is the topic and `-a` is the address the webhook should be sent to.
