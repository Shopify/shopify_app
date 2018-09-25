# karma-mocha-debug

> Improve [karma-mocha](https://github.com/karma-runner/karma-mocha) plugin

## Installation

The easiest way is to keep `karma-mocha-debug` as a devDependency in your `package.json`.
```json
{
  "devDependencies": {
    "karma": "~0.10",
    "karma-mocha": "~0.1",
    "karma-mocha-debug": "~0.1"
  }
}
```

You can simple do it by:
```bash
npm install karma-mocha-debug --save-dev
```

## Configuration
You should put mocha-debug before mocha
```js
// karma.conf.js
module.exports = function(config) {
  config.set({
    frameworks: ['mocha-debug', 'mocha'],
  });
};
```

## Usage

Mocha **HTML reporter on debug page**.

Now you can open http://localhost:9876/debug.html and see mocha html report
instead default karma console report.

Run *grep* from console.

You can use mocha grep from console.

```bash
karma start &
karma run -- --grep=my_test
```

----

For more information on Karma see the [homepage].

[homepage]: http://karma-runner.github.com
