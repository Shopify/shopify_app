"use strict";

var assert = require("@sinonjs/referee-sinon").assert;
var index = require("./index");

describe("package", function() {
    var expectedExports = [
        "every",
        "functionName",
        "prototypes",
        "typeOf",
        "valueToString"
    ];
    Object.keys(index).forEach(function(name) {
        assert.isTrue(expectedExports.includes(name));
    });
});
