"use strict";

var from = require("array-from");

function isSubset(s1, s2, compare) {
    // FIXME: IE11 doesn't support Array.from
    // Potential solutions:
    // - contribute a patch to https://github.com/Volox/eslint-plugin-ie11#readme
    // - https://github.com/mathiasbynens/Array.from (doesn't work with matchers)
    var values1 = from(s1);
    var values2 = from(s2);

    for (var i = 0; i < values1.length; i++) {
        var includes = false;

        for (var j = 0; j < values2.length; j++) {
            if (compare(values2[j], values1[i])) {
                includes = true;
                break;
            }
        }

        if (!includes) {
            return false;
        }
    }

    return true;
}

module.exports = isSubset;
