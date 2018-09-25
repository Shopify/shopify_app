karma-chai-sinon
==========

[Chai](http://chaijs.com) + [Sinon-Chai](http://chaijs.com/plugins/sinon-chai) + [Sinon](http://sinonjs.org/) for [Karma](http://karma-runner.github.io)

*What makes this plugin different from `karma-sinon-chai`?*
* It allows you to use either the latest versions of sinon, chai and sinon-chai or the specific versions your project already uses.
* It uses `peerDependencies` only.
* No `bower` dependency.

[![NPM](https://nodei.co/npm/karma-chai-sinon.png?downloads=true)](https://npmjs.org/package/karma-chai-sinon)

Installation
------------

Install the plugin from npm:

```sh
$ npm install karma-chai-sinon --save-dev
```

Install the plugin from Github:

```sh
$ npm install 'git://github.com/tubalmartin/karma-chai-sinon.git' --save-dev
```

Add `chai-sinon` to the `frameworks` key in your Karma configuration:

```js
module.exports = function(config) {
  config.set({

    // frameworks to use
    frameworks: ['mocha', 'chai-sinon']

    // ...
```

License
-------

The MIT License (MIT)
