"use strict";

function getClassName(value) {
    return Object.getPrototypeOf(value) ? value.constructor.name : null;
}

module.exports = getClassName;
