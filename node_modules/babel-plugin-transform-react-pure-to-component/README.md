# babel-plugin-transform-react-pure-to-component

This plugin transforms any class extending React’s `PureComponent` to extend `Component` instead. This should only be enabled in development, and only when using hot reloading. Extending `Component` in all cases in development means that changes to the `render` method of your component will be run, where `PureComponent`s will opt out via their `componentWillUpdate()` checks.

## Example

**In**

```js
import React, {PureComponent} from 'react';

class MyComponent extends PureComponent {}
```

**Out**

```js
import React, {Component as _Component} from 'react';

class MyComponent extends _Component {}
```

This plugin also handles cases where you use a namespace import (`import * as React from 'react';`), default imports with properties (`import React from 'react'; class MyComponent extends React.PureComponent {}`), and named imports other than `React`/ `PureComponent`.

## Installation

```sh
# yarn
yarn add --dev babel-plugin-pure-to-impure-component

# npm
npm install --save-dev babel-plugin-pure-to-impure-component
```

## Usage

### Via `.babelrc` (Recommended)

**.babelrc**

```json
{
  "plugins": ["transform-react-pure-to-component"]
}
```

### Via CLI

```sh
babel --plugins transform-react-pure-to-component script.js
```

### Via Node API

```js
require('babel-core').transform('code', {
  plugins: ['transform-react-pure-to-component'],
});
```
