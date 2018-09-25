# babel-preset-shopify

[![NPM version][npm-image]][npm-url]

Shopify’s org-wide set of Babel transforms.

## Usage

Install this package, as well as the parts of Babel you wish to use:

**With Yarn**

```bash
yarn add --dev --exact babel-core babel-preset-shopify
```

**With npm**

```bash
npm install babel-core babel-preset-shopify --save-dev --save-exact
```

Then, in your Babel configuration (which should be under the `babel` key of your `package.json`), set this package as the babel preset you’d like to use:

```json
{
  "babel": {
    "presets": ["shopify/web"]
  }
}
```

## Presets

This packages comes with several different presets for you to use, depending on your project:

- `shopify`: The same as `shopify/web`.

- `shopify/web`: A preset to use for JavaScript that is meant to run in browsers. It compiles down features to only those supported by browsers that Shopify’s admin runs on. Note that many modern JavaScript features, like `Map`s, `Set`s, `for of` loops, and more, require runtime polyfills (we recommend [`babel-polyfill`](https://babeljs.io/docs/usage/polyfill/), as our `web` and `node` configs will reduce these imports to the set of features needed to polyfill your target environment).

  This preset accepts an options object. The following options are allowed:

    - `modules`, a boolean indicating whether native ES2015 modules should be transpiled to CommonJS equivalents. Set this option to `false` when you are using a bundler like Rollup or Webpack 2:

      ```json
      {
        "babel": {
          "presets": [
            ["shopify/web", {"modules": false}]
          ]
        }
      }
      ```

    - `browsers`, a [browserslist](https://github.com/ai/browserslist) string or array, which specifies which browsers to transpile for. Defaults to the list found in `browsers.js`.

      ```json
      {
        "babel": {
          "presets": [
            ["shopify/web", {
              "browsers": ["last 3 versions"]
            }]
          ]
        }
      }
      ```

    - `inlineEnv`, a boolean (defaults to `false`) to automatically replace `process.env.<VAR>` statements with the corresponding environment variable.

    - `debug`, a boolean (defaults to `false`) to turn on [`babel-preset-env` debugging](https://github.com/babel/babel/tree/master/packages/babel-preset-env#debug).

  Note that when using this config, you should also install `babel-polyfill` as a production dependency (`yarn add babel-polyfill` or `npm install --save babel-polyfill`). This package will be used to reduce duplication of common Babel helpers.

- `shopify/node`: This preset transpiles features to a specified version of Node, defaulting to the currently active version. It accepts an options object. The `modules` and `inlineEnv` do the same thing they do in `shopify/web`, detailed above. You can also pass a version of Node to target during transpilation using the `version` option:

  ```json
  {
    "babel": {
      "presets": [
        ["shopify/node", {
          "modules": false,
          "version": 4
        }]
      ]
    }
  }
  ```

  As with `shopify/web`, you should install `babel-polyfill` to help reduce the duplication of Babel helpers.

- `shopify/react`: Adds plugins that transform React (including JSX). You can use this preset with the `shopify/web` or `shopify/node` configuration. Note that if you enable this, you do not need to also enable the `shopify/flow` config (it is included automatically). You will, however, need to include an `Object.assign` polyfill in your bundle (we recommend the polyfills found in [`babel-polyfill`](https://babeljs.io/docs/usage/polyfill/)).

  This preset accepts an options object.
  - `hot` : Will automatically add plugins to enable hot reloading of React components. Note that this requires you to have a recent version of `react-hot-loader` installed as a dependency in your project.
  - `pragma` : Replace the function used when compiling JSX expressions. defaults to `React.createElement`.

  ```json
  {
    "babel": {
      "presets": [
        ["shopify/react", {"hot": true}]
      ]
    }
  }
  ```

- `shopify/flow`: Adds plugins that transform Flow type annotations. You can use this preset with `shopify/web` or `shopify/node`.

As noted above, you can include multiple of these presets together. Some common recipes are shown below:

```js
// A React project without any server component, using sprockets-commoner for bundling
{
  "babel": {
    "presets": [
      "shopify/web",
      "shopify/react"
    ]
  }
}

// A Node project using flow and Rollup to create a single bundle
{
  "babel": {
    "presets": [
      ["shopify/node", {"modules": false}],
      "shopify/flow"
    ]
  }
}
```

[npm-url]: https://npmjs.org/package/babel-preset-shopify
[npm-image]: http://img.shields.io/npm/v/babel-preset-shopify.svg?style=flat-square
