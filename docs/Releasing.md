# Releasing ShopifyApp

1. Make the code changes in a separate PR that doesn't modify the version.
1. After that is merged, check the Semantic Versioning page for info on how to version the new release: http://semver.org
1. Create a pull request with the following changes:
    - Update the version of ShopifyApp in lib/shopify_app/version.rb
    - Update the version of shopify_app in package.json
    - Run `bundle` to update `Gemfile.lock`
    - Add a CHANGELOG entry for the new release with the date
    - Change the title of the PR to something like: "Packaging for release X.Y.Z"
1. Merge your pull request
1. Checkout and pull from master so you have the latest version of the shopify_app
1. Tag the HEAD with the version
    ```bash
    $ git tag -f vX.Y.Z && git push --tags --force
    ```
1. Check that Create Release workflow successfully runs
1. Use Shipit to build and push the gem

If you see an error like 'You need to create the vX.Y.X tag first', clear git
cache in Shipit settings
