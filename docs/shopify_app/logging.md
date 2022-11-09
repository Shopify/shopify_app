# Logging

## Log Levels

1. Debug
2. Info
3. Warn
4. Error

We have four log levels with `error` being the most severe.

## Configuration

You can configure your log level by changing your `SHOPIFY_LOG_LEVEL` environment variable. If `SHOPIFY_LOG_LEVEL` is not set the configuration file with default to `info`. To turn off all shopify_app logs you can change this environment variable to `off`.
