"use strict";

var deepEqualCyclic = require("./deep-equal");
var identical = require("./identical");
var isArguments = require("./is-arguments");
var isElement = require("./is-element");
var isNegZero = require("./is-neg-zero");
var match = require("./match");

module.exports = {
    isArguments: isArguments,
    isElement: isElement,
    isNegZero: isNegZero,
    identical: identical,
    deepEqual: deepEqualCyclic,
    match: match
};
