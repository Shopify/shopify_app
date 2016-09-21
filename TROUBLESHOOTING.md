Troubleshooting Shopify App
===========

### Generator shopify_app:install hangs

Rails uses spring by default to speed up development. To run the generator, spring has to be stopped:

```sh
$ bundle exec spring stop
```

Run shopify_app generator again.

### App installation fails with 'The page you’re looking for could not be found' if the app was installed before

This issue can occur when the session (the model you set as `ShopifyApp::SessionRepository.storage`) isn't deleted when the user uninstalls your app. A possible fix for this is listening to the `app/uninstalled` webhook and deleting the corresponding session in the webhook handler.
