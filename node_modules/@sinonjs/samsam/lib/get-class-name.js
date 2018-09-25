"use strict";

function getClassName(value) {
    return value.constructor ? value.constructor.name : null;
}

module.exports = getClassName;
