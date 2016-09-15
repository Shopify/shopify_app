#Shopify Embedded Application Example


This is an example embedded application generated using this gem.

# Setting up this application

Create a `.env` file for your application credentials. These credentials are generated in your Shopify Partner account for your app:

```
SHOPIFY_CLIENT_API_KEY=<your key>
SHOPIFY_CLIENT_API_SECRET=<your secret>
```

Note that your app must have the Embedded App SDK enabled in that same partner account page.

Install the gems:

    bundle install

Create necessary tables:

    rake db:migrate

Run the server:

    bundle exec rails server

To install the application on your dev-shop go to:

    http://localhost:3000/login?shop=<yourdevshop-url.myshopify.com>

You will be prompted to install the application and will be redirected to the embedded Shopify environment once installed.

For local development most modern browsers will block mixed content. Since Shopify runs on HTTPS and a local development server does not, the browser will block the contents of the iframe. You can either explicitly allow mixed content for your session, or use an HTTPS forwarding service.
