# Quickstart

This guide assumes you have completed the steps to create a new Rails app using the Shopify App gem found in the [*Usage*](/README.md#usage) section of the project's [*README*](/README.md).

#### Table of contents

[Optionally Setup SSH tunnel for development](#setup-ssh-tunnel-for-development)

[Use Shopify App Bridge to embed your app in the Shopify Admin](#use-shopify-app-bridge-to-embed-your-app-in-the-shopify-admin)

## Optionally Setup SSH tunnel for development

Local development supports both `http` and `https` schemes. By default `http` and localhost are used.

To use `https`, your local app needs to be accessible from the public Internet in order to install it on a Shopify store to use the [App Proxy Controller](/lib/generators/shopify_app/app_proxy_controller/templates/app_proxy_controller.rb) or receive [webhooks](/docs/shopify_app/webhooks.md).

In order to receive requests securely, you'll need to setup a tunnel from the internet to localhost. You can use [Cloudflare](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/run-tunnel/trycloudflare/) for this.

To do so, [install the `cloudflared` CLI tool](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/), and run:

```sh
# The port must be the same as the one you run the Rails app on later. We use the Rails default below.
cloudflared tunnel --url http://localhost:3000
```

Keep this window running to keep the tunnel and make note of the URL this command prints out. The URL will look like `https://some-random-words.trycloudflare.com`.

Visit the "App Setup" section for your app in the [Shopify Partners dashboard](https://partners.shopify.com/organizations). Set the URL as "App URL" on this settings page and add it to the "Allowed redirection URL(s)", after appending `/auth/shopify/callback` to the end (e.g. `https://some-random-words.trycloudflare.com/auth/shopify/callback`).

Add the same URL as `SHOPIFY_APP_URL` in your `.env` file e.g.
```sh
SHOPIFY_APP_URL='https://some-random-words.trycloudflare.com/'
```

<!-- TODO Update CLI version here -->
> **Note**: For apps created using Shopify CLI vX.Y.Z or earlier, some of the environment variables above use different names.
>
> For more information, refer to [Shopify CLI app structure](https://shopify.dev/docs/apps/tools/cli/structure#web-component-conventions).

## Use Shopify App Bridge to embed your app in the Shopify Admin

A basic example of using [*Shopify App Bridge*](https://shopify.dev/tools/app-bridge) is included in the install generator. An instance Shopify App Bridge is automatically initialized in [shopify_app.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/shopify_app.js). 

The [flash_messages.js](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/flash_messages.js) file converts Rails [flash messages](https://api.rubyonrails.org/classes/ActionDispatch/Flash.html) to App Bridge Toast actions automatically. By default, this library is included via [unpkg in the embedded_app layout](https://github.com/Shopify/shopify_app/blob/master/lib/generators/shopify_app/install/templates/embedded_app.html.erb#L27). 

For more advanced uses it is recommended to [install App Bridge via npm or yarn](https://help.shopify.com/en/api/embedded-apps/app-bridge/getting-started#set-up-shopify-app-bridge-in-your-app).
