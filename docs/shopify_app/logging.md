# Logging

## Log Levels

There are four log levels with `error` being the most severe.

1. Debug
2. Info
3. Warn
4. Error

## Configuration

The logging is controlled by the `log_level` configuration setting.
The default log level is `:info`.
You can disable all logs by setting this to `:off`.

## Upgrading

For a newly-generated app, the `shopify_app` initializer will contain the `log_level` setting.
If you are upgrading from a previous version of the `shopify_app` gem then you will need to add this manually, otherwise it will default to `:info`.