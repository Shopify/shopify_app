# Logging

## Log Levels

1. Debug
2. Info
3. Warn
4. Error

We have four log levels with `error` being the most severe.

## Configuration

Your log level is set to `:info` by default. You can change this by going into your configuration file and changing the `log_level` setting. You can remove all logs by setting this to `:off`.

## Upgrading

Make sure to add the `config.log_level` setting to your configuration file so you can start changing the log level to your preference. If `log_level` isn't found if your configuration settings then it will default to the `:info` level.
