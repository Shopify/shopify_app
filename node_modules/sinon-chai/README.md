# Sinon.JS Assertions for Chai

**Sinon–Chai** provides a set of custom assertions for using the [Sinon.JS][] spy, stub, and mocking framework with the
[Chai][] assertion library. You get all the benefits of Chai with all the powerful tools of Sinon.JS.

Instead of using Sinon.JS's assertions:

```javascript
sinon.assert.calledWith(mySpy, "foo");
```

or awkwardly trying to use Chai's `should` or `expect` interfaces on spy properties:

```javascript
mySpy.calledWith("foo").should.be.ok;
expect(mySpy.calledWith("foo")).to.be.ok;
```

you can say

```javascript
mySpy.should.have.been.calledWith("foo");
expect(mySpy).to.have.been.calledWith("foo");
```

## Assertions

All of your favorite Sinon.JS assertions made their way into Sinon–Chai. We show the `should` syntax here; the `expect`
equivalent is also available.

| Sinon.JS property/method | Sinon–Chai assertion                                              |
|--------------------------|-------------------------------------------------------------------|
| called                   | spy.should.have.been.called                                       |
| callCount                | spy.should.have.callCount(n)                                      |
| calledOnce               | spy.should.have.been.calledOnce                                   |
| calledTwice              | spy.should.have.been.calledTwice                                  |
| calledThrice             | spy.should.have.been.calledThrice                                 |
| calledBefore             | spy1.should.have.been.calledBefore(spy2)                          |
| calledAfter              | spy1.should.have.been.calledAfter(spy2)                           |
| calledImmediatelyBefore  | spy.should.have.been.calledImmediatelyBefore(spy2)                |
| calledImmediatelyAfter   | spy.should.have.been.calledImmediatelyAfter(spy2)                 |
| calledWithNew            | spy.should.have.been.calledWithNew                                |
| alwaysCalledWithNew      | spy.should.always.have.been.calledWithNew                         |
| calledOn                 | spy.should.have.been.calledOn(context)                            |
| alwaysCalledOn           | spy.should.always.have.been.calledOn(context)                     |
| calledWith               | spy.should.have.been.calledWith(...args)                          |
| alwaysCalledWith         | spy.should.always.have.been.calledWith(...args)                   |
| calledOnceWith           | spy.should.always.have.been.calledOnceWith(...args)               |
| calledWithExactly        | spy.should.have.been.calledWithExactly(...args)                   |
| alwaysCalledWithExactly  | spy.should.always.have.been.calledWithExactly(...args)            |
| calledOnceWithExactly    | spy.should.always.have.been.calledOnceWithExactly(...args)        |
| calledWithMatch          | spy.should.have.been.calledWithMatch(...args)                     |
| alwaysCalledWithMatch    | spy.should.always.have.been.calledWithMatch(...args)              |
| returned                 | spy.should.have.returned(returnVal)                               |
| alwaysReturned           | spy.should.have.always.returned(returnVal)                        |
| threw                    | spy.should.have.thrown(errorObjOrErrorTypeStringOrNothing)        |
| alwaysThrew              | spy.should.have.always.thrown(errorObjOrErrorTypeStringOrNothing) |

For more information on the behavior of each assertion, see
[the documentation for the corresponding spy methods][spymethods]. These of course work on not only spies, but
individual spy calls, stubs, and mocks as well.

Note that you can negate any assertion with Chai's `.not`. E. g. for `notCalled` use `spy.should.have.not.been.called`.

For `assert` interface there is no need for this library. You can install [Sinon.JS assertions][sinonassertions] right into Chai's `assert` object with `expose`:

```javascript
var chai = require("chai");
var sinon = require("sinon");

sinon.assert.expose(chai.assert, { prefix: "" });
```

## Examples

Using Chai's `should`:

```javascript
"use strict";
var chai = require("chai");
var sinon = require("sinon");
var sinonChai = require("sinon-chai");
chai.should();
chai.use(sinonChai);

function hello(name, cb) {
    cb("hello " + name);
}

describe("hello", function () {
    it("should call callback with correct greeting", function () {
        var cb = sinon.spy();

        hello("foo", cb);

        cb.should.have.been.calledWith("hello foo");
    });
});
```

Using Chai's `expect`:

```javascript
"use strict";
var chai = require("chai");
var sinon = require("sinon");
var sinonChai = require("sinon-chai");
var expect = chai.expect;
chai.use(sinonChai);

function hello(name, cb) {
    cb("hello " + name);
}

describe("hello", function () {
    it("should call callback with correct greeting", function () {
        var cb = sinon.spy();

        hello("foo", cb);

        expect(cb).to.have.been.calledWith("hello foo");
    });
});
```

## Installation and Usage

### Node

Do an `npm install sinon-chai` to get up and running. Then:

```javascript
var chai = require("chai");
var sinonChai = require("sinon-chai");

chai.use(sinonChai);
```

You can of course put this code in a common test fixture file; for an example using [Mocha][], see
[the Sinon–Chai tests themselves][fixturedemo].

### AMD

Sinon–Chai supports being used as an [AMD][] module, registering itself anonymously (just like Chai). So, assuming you
have configured your loader to map the Chai and Sinon–Chai files to the respective module IDs `"chai"` and
`"sinon-chai"`, you can use them as follows:

```javascript
define(function (require, exports, module) {
    var chai = require("chai");
    var sinonChai = require("sinon-chai");

    chai.use(sinonChai);
});
```

### `<script>` tag

If you include Sinon–Chai directly with a `<script>` tag, after the one for Chai itself, then it will automatically plug
in to Chai and be ready for use. Note that you'll want to get the latest browser build of Sinon.JS as well:

```html
<script src="chai.js"></script>
<script src="sinon-chai.js"></script>
<script src="sinon.js"></script>
```

### Ruby on Rails

Thanks to [Cymen Vig][], there's now [a Ruby gem][] of Sinon–Chai that integrates it with the Rails asset pipeline!


[Sinon.JS]: http://sinonjs.org/
[Chai]: http://chaijs.com/
[spymethods]: http://sinonjs.org/docs/#spies-api
[sinonassertions]: http://sinonjs.org/docs/#assertions
[Mocha]: https://mochajs.org/
[fixturedemo]: https://github.com/domenic/sinon-chai/tree/master/test/
[AMD]: https://github.com/amdjs/amdjs-api/wiki/AMD
[Cymen Vig]: https://github.com/cymen
[a Ruby gem]: https://github.com/cymen/sinon-chai-rails
