# Quickstart

This guide assumes you have completed the steps to create a new Rails app using the Shopify App gem found in the [*Usage*](/README.md#usage) section of the project's [*README*](/README.md).

#### Table of contents

[Make your app available to the internet](#make-your-app-available-to-the-internet)

[Use Shopify App Bridge to embed your app in the Shopify Admin](#use-shopify-app-bridge-to-embed-your-app-in-the-shopify-admin)

## Make your app available to the internet

Your local app needs to be accessible from the public Internet in order to install it on a Shopify store, to use the [App Proxy Controller](/README.md#-rails-generate-shopifyappapp-proxy-controller) or receive [webhooks](/docs/shopify_app/webhooks.md).

Use a tunneling service like [ngrok](https://ngrok.com/), [Beeceptor](https://beeceptor.com/), [Mockbin](http://mockbin.org/), or [Hookbin](https://hookbin.com/) to make your development environment accessible to the internet.

For example with [ngrok](https://ngrok.com/), run this command to set up a tunnel proxy to Rails' default port:

```sh
ngrok http 3000
```

See the [*Embed the app in Shopify*](https://shopify.dev/tutorials/build-rails-react-app-that-uses-app-bridge-authentication#embed-the-app-in-shopify) section of [*Build a Shopify app with Rails, React, and App Bridge*](https://shopify.dev/tutorials/build-rails-react-app-that-uses-app-bridge-authentication) to learn more.

## Use Shopify App Bridge to embed your app in the Shopify Admin

A basic example of using [*Shopify App Bridge*](https://shopify.dev/tools/app-bridge) is included in the install generator. An instance Shopify App Bridge is automatically initialized in [shopify_app.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/shopify_app.js). 

The [flash_messages.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/flash_messages.js) file converts Rails [flash messages](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html) to App Bridge Toast actions automatically. By default, this library is included via [unpkg in the embedded_app layout](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/embedded_app.html.erb#L27). 

For more advanced uses it is recommended to [install App Bridge via npm or yarn](https://help.shopify.com/en/api/embedded-apps/app-bridge/getting-started#set-up-shopify-app-bridge-in-your-app).
