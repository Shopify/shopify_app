# Unreleased
Nil.

# 16.3.0
## Added
- `shopify/web` and `shopify/node` now accept an addition option, `debug`. When passed, this enables `babel-preset-env`'s debugging to show why transforms are being included in a project. Defaults to `false` (current behaviour).

# 16.2.0
## Added
- Added `babel-plugin-syntax-dynamic-import` to the web config.

# 16.1.0
## Added
- Added a Babel plugin to remove `testID` props in non-test environments.

# 16.0.2
## Updated
- Integrated bugfix from most recent version of `babel-plugin-transform-react-pure-to-component`.

# 16.0.1
## Fixed
- `shopify/web` and `shopify/node` now correctly default the `modules` option to `'commonjs'` instead of `true`.

# 16.0.0
## Added
- `shopify/react` now includes a `hot` option to enable plugins related to hot reloading (`react-hot-loader` and `react-pure-to-component`).
- `shopify/react` now includes plugins in development that add additional information for debugging purposes, and plugins in production that offer some performance optimizations.
- `shopify/web` now accepts an additional option, `browsers` (an array of [`browserslist`](https://github.com/ai/browserslist) strings) which specifies what browsers to transpile for (defaults to the browsers supported by Shopify’s admin).

## Updated
- `shopify/web` and `shopify/node` presets now use [`babel-preset-env`](https://github.com/babel/babel-preset-env) to transpile only the features needed for the target environment.
- Updated all versions of dependend-on plugins and presets.

# 15.0.1
- Initial move from combined `javascript` repo.
