# Webhooks

#### Table of contents

[Manage webhooks using `ShopifyApp::WebhooksManager`](#manage-webhooks-using-shopifyappwebhooksmanager)
[Mandatory Privacy Webhooks](#mandatory-privacy-webhooks)

## Manage webhooks using `ShopifyApp::WebhooksManager`

See [`ShopifyApp::WebhooksManager`](/lib/shopify_app/managers/webhooks_manager.rb)
ShopifyApp can manage your app's webhooks for you if you set which webhooks you require in the initializer:

```ruby
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'carts/update', path: 'webhooks/carts_update'}
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
    {topic: 'products/update', path: 'webhooks/products_update', fields: ['title', 'vendor']}
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
rails g shopify_app:add_webhook --topic carts/update --path webhooks/carts_update
```

Where `--topic` is the topic and `--path` is the path the webhook should be sent to.

## Mandatory Privacy Webhooks

We have three mandatory privacy webhooks

1. `customers/data_request`
2. `customer/redact`
3. `shop/redact`

The `generate shopify_app` command generated three job templates corresponding to all three of these webhooks.
To pass our approval process you will need to set these webhooks in your partner dashboard.
You can read more about that [here](https://shopify.dev/apps/webhooks/configuration/mandatory-webhooks).

## EventBridge and PubSub Webhooks

You can also register webhooks for delivery to Amazon EventBridge or Google Cloud Pub/Sub. In this case the `path` argument to needs to be of a specific form.

For EventBridge, the `path` must be the ARN of the partner event source.

```rb
ShopifyApp.configure do |config|
  config.webhooks = [
    {
      delivery_method: :event_bridge,
      topic: 'carts/update',
      path: 'arn:aws:events....'
    }
  ]
end
```

For Pub/Sub, the `path` must be of the form `pubsub://[PROJECT-ID]:[PUB-SUB-TOPIC-ID]`. For example, if you created a topic with id `red` in the project `blue`, then the value of path would be `pubsub://blue:red`.

```rb
ShopifyApp.configure do |config|
  config.webhooks = [
    {
      delivery_method: :pub_sub,
      topic: 'carts/update',
      path: 'pubsub://project-id:pub-sub-topic-id'
    }
  ]
end
```

When registering for an EventBridge or PubSub Webhook you'll need to implement a handler that will fetch webhooks from the queue and process them yourself.
