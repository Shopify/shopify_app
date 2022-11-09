# Logging

## Log Levels

1. Debug
2. Info
3. Warn
4. Error

We have four log levels with `error` being the most severe. You can configure your log level by changing your `SHOPIFY_LOG_LEVEL` environment variable. If you don't have a `SHOPIFY_LOG_LEVEL` set your `shopify_app.rb` configuration file with default to `info`. To turn off all shopify_app logs you can change this environment variable to `off`.
