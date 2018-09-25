(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('array-from')) :
    typeof define === 'function' && define.amd ? define(['exports', 'array-from'], factory) :
    (factory((global.samsam = {}),global.arrayFrom));
}(this, (function (exports,arrayFrom) { 'use strict';

    arrayFrom = arrayFrom && arrayFrom.hasOwnProperty('default') ? arrayFrom['default'] : arrayFrom;

    var o = Object.prototype;

    function getClass(value) {
        // Returns the internal [[Class]] by calling Object.prototype.toString
        // with the provided value as this. Return value is a string, naming the
        // internal class, e.g. "Array"
        return o.toString.call(value).split(/[ \]]/)[1];
    }

    var getClass_1 = getClass;

    function isNaN(value) {
        // Unlike global isNaN, this avoids type coercion
        // typeof check avoids IE host object issues, hat tip to
        // lodash
        var val = value; // JsLint thinks value !== value is "weird"
        return typeof value === "number" && value !== val;
    }

    var isNan = isNaN;

    /**
     * @name samsam.isNegZero
     * @param Object value
     *
     * Returns ``true`` if ``value`` is ``-0``.
     */
    function isNegZero(value) {
        return value === 0 && 1 / value === -Infinity;
    }

    var isNegZero_1 = isNegZero;

    /**
     * @name samsam.equal
     * @param Object obj1
     * @param Object obj2
     *
     * Returns ``true`` if two objects are strictly equal. Compared to
     * ``===`` there are two exceptions:
     *
     *   - NaN is considered equal to NaN
     *   - -0 and +0 are not considered equal
     */
    function identical(obj1, obj2) {
        if (obj1 === obj2 || (isNan(obj1) && isNan(obj2))) {
            return obj1 !== 0 || isNegZero_1(obj1) === isNegZero_1(obj2);
        }

        return false;
    }

    var identical_1 = identical;

    /**
     * @name samsam.isArguments
     * @param Object object
     *
     * Returns ``true`` if ``object`` is an ``arguments`` object,
     * ``false`` otherwise.
     */
    function isArguments(object) {
        if (getClass_1(object) === "Arguments") {
            return true;
        }
        if (
            typeof object !== "object" ||
            typeof object.length !== "number" ||
            getClass_1(object) === "Array"
        ) {
            return false;
        }
        if (typeof object.callee === "function") {
            return true;
        }
        try {
            object[object.length] = 6;
            delete object[object.length];
        } catch (e) {
            return true;
        }
        return false;
    }

    var isArguments_1 = isArguments;

    function isDate(value) {
        return value instanceof Date;
    }

    var isDate_1 = isDate;

    var div = typeof document !== "undefined" && document.createElement("div");

    /**
     * @name samsam.isElement
     * @param Object object
     *
     * Returns ``true`` if ``object`` is a DOM element node. Unlike
     * Underscore.js/lodash, this function will return ``false`` if ``object``
     * is an *element-like* object, i.e. a regular object with a ``nodeType``
     * property that holds the value ``1``.
     */
    function isElement(object) {
        if (!object || object.nodeType !== 1 || !div) {
            return false;
        }
        try {
            object.appendChild(div);
            object.removeChild(div);
        } catch (e) {
            return false;
        }
        return true;
    }

    var isElement_1 = isElement;

    // Returns true when the value is a regular Object and not a specialized Object
    //
    // This helps speeding up deepEqual cyclic checks
    // The premise is that only Objects are stored in the visited array.
    // So if this function returns false, we don't have to do the
    // expensive operation of searching for the value in the the array of already
    // visited objects
    function isObject(value) {
        return (
            typeof value === "object" &&
            value !== null &&
            // none of these are collection objects, so we can return false
            !(value instanceof Boolean) &&
            !(value instanceof Date) &&
            !(value instanceof Error) &&
            !(value instanceof Number) &&
            !(value instanceof RegExp) &&
            !(value instanceof String)
        );
    }

    var isObject_1 = isObject;

    function isSet(val) {
        return (typeof Set !== "undefined" && val instanceof Set) || false;
    }

    var isSet_1 = isSet;

    function isSubset(s1, s2, compare) {
        // FIXME: IE11 doesn't support Array.from
        // Potential solutions:
        // - contribute a patch to https://github.com/Volox/eslint-plugin-ie11#readme
        // - https://github.com/mathiasbynens/Array.from (doesn't work with matchers)
        var values1 = arrayFrom(s1);
        var values2 = arrayFrom(s2);

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

    var isSubset_1 = isSubset;

    function getClassName(value) {
        return Object.getPrototypeOf(value) ? value.constructor.name : null;
    }

    var getClassName_1 = getClassName;

    var every = Array.prototype.every;
    var getTime = Date.prototype.getTime;
    var hasOwnProperty = Object.prototype.hasOwnProperty;
    var indexOf = Array.prototype.indexOf;
    var keys = Object.keys;

    /**
     * @name samsam.deepEqual
     * @param Object first
     * @param Object second
     *
     * Deep equal comparison. Two values are "deep equal" if:
     *
     *   - They are equal, according to samsam.identical
     *   - They are both date objects representing the same time
     *   - They are both arrays containing elements that are all deepEqual
     *   - They are objects with the same set of properties, and each property
     *     in ``first`` is deepEqual to the corresponding property in ``second``
     *
     * Supports cyclic objects.
     */
    function deepEqualCyclic(first, second) {
        // used for cyclic comparison
        // contain already visited objects
        var objects1 = [];
        var objects2 = [];
        // contain pathes (position in the object structure)
        // of the already visited objects
        // indexes same as in objects arrays
        var paths1 = [];
        var paths2 = [];
        // contains combinations of already compared objects
        // in the manner: { "$1['ref']$2['ref']": true }
        var compared = {};

        // does the recursion for the deep equal check
        return (function deepEqual(obj1, obj2, path1, path2) {
            var type1 = typeof obj1;
            var type2 = typeof obj2;

            // == null also matches undefined
            if (
                obj1 === obj2 ||
                isNan(obj1) ||
                isNan(obj2) ||
                obj1 == null ||
                obj2 == null ||
                type1 !== "object" ||
                type2 !== "object"
            ) {
                return identical_1(obj1, obj2);
            }

            // Elements are only equal if identical(expected, actual)
            if (isElement_1(obj1) || isElement_1(obj2)) {
                return false;
            }

            var isDate1 = isDate_1(obj1);
            var isDate2 = isDate_1(obj2);
            if (isDate1 || isDate2) {
                if (
                    !isDate1 ||
                    !isDate2 ||
                    getTime.call(obj1) !== getTime.call(obj2)
                ) {
                    return false;
                }
            }

            if (obj1 instanceof RegExp && obj2 instanceof RegExp) {
                if (obj1.toString() !== obj2.toString()) {
                    return false;
                }
            }

            if (obj1 instanceof Error && obj2 instanceof Error) {
                if (obj1.stack !== obj2.stack) {
                    return false;
                }
            }

            var class1 = getClass_1(obj1);
            var class2 = getClass_1(obj2);
            var keys1 = keys(obj1);
            var keys2 = keys(obj2);
            var name1 = getClassName_1(obj1);
            var name2 = getClassName_1(obj2);

            if (isArguments_1(obj1) || isArguments_1(obj2)) {
                if (obj1.length !== obj2.length) {
                    return false;
                }
            } else {
                if (
                    type1 !== type2 ||
                    class1 !== class2 ||
                    keys1.length !== keys2.length ||
                    (name1 && name2 && name1 !== name2)
                ) {
                    return false;
                }
            }

            if (isSet_1(obj1) || isSet_1(obj2)) {
                if (!isSet_1(obj1) || !isSet_1(obj2) || obj1.size !== obj2.size) {
                    return false;
                }

                return isSubset_1(obj1, obj2, deepEqual);
            }

            return every.call(keys1, function(key) {
                if (!hasOwnProperty.call(obj2, key)) {
                    return false;
                }

                var value1 = obj1[key];
                var value2 = obj2[key];
                var isObject1 = isObject_1(value1);
                var isObject2 = isObject_1(value2);
                // determines, if the objects were already visited
                // (it's faster to check for isObject first, than to
                // get -1 from getIndex for non objects)
                var index1 = isObject1 ? indexOf.call(objects1, value1) : -1;
                var index2 = isObject2 ? indexOf.call(objects2, value2) : -1;
                // determines the new paths of the objects
                // - for non cyclic objects the current path will be extended
                //   by current property name
                // - for cyclic objects the stored path is taken
                var newPath1 =
                    index1 !== -1
                        ? paths1[index1]
                        : path1 + "[" + JSON.stringify(key) + "]";
                var newPath2 =
                    index2 !== -1
                        ? paths2[index2]
                        : path2 + "[" + JSON.stringify(key) + "]";
                var combinedPath = newPath1 + newPath2;

                // stop recursion if current objects are already compared
                if (compared[combinedPath]) {
                    return true;
                }

                // remember the current objects and their paths
                if (index1 === -1 && isObject1) {
                    objects1.push(value1);
                    paths1.push(newPath1);
                }
                if (index2 === -1 && isObject2) {
                    objects2.push(value2);
                    paths2.push(newPath2);
                }

                // remember that the current objects are already compared
                if (isObject1 && isObject2) {
                    compared[combinedPath] = true;
                }

                // End of cyclic logic

                // neither value1 nor value2 is a cycle
                // continue with next level
                return deepEqual(value1, value2, newPath1, newPath2);
            });
        })(first, second, "$1", "$2");
    }

    var deepEqual = deepEqualCyclic;

    function arrayContains(array, subset, compare) {
        if (subset.length === 0) {
            return true;
        }
        var i, l, j, k;
        for (i = 0, l = array.length; i < l; ++i) {
            if (compare(array[i], subset[0])) {
                for (j = 0, k = subset.length; j < k; ++j) {
                    if (i + j >= l) {
                        return false;
                    }
                    if (!compare(array[i + j], subset[j])) {
                        return false;
                    }
                }
                return true;
            }
        }
        return false;
    }

    /**
     * @name samsam.match
     * @param Object object
     * @param Object matcher
     *
     * Compare arbitrary value ``object`` with matcher.
     */
    function match(object, matcher) {
        if (matcher && typeof matcher.test === "function") {
            return matcher.test(object);
        }

        if (typeof matcher === "function") {
            return matcher(object) === true;
        }

        if (typeof matcher === "string") {
            matcher = matcher.toLowerCase();
            var notNull = typeof object === "string" || !!object;
            return (
                notNull &&
                String(object)
                    .toLowerCase()
                    .indexOf(matcher) >= 0
            );
        }

        if (typeof matcher === "number") {
            return matcher === object;
        }

        if (typeof matcher === "boolean") {
            return matcher === object;
        }

        if (typeof matcher === "undefined") {
            return typeof object === "undefined";
        }

        if (matcher === null) {
            return object === null;
        }

        if (isSet_1(object)) {
            return isSubset_1(matcher, object, match);
        }

        if (getClass_1(object) === "Array" && getClass_1(matcher) === "Array") {
            return arrayContains(object, matcher, match);
        }

        if (isDate_1(matcher)) {
            return isDate_1(object) && object.getTime() === matcher.getTime();
        }

        if (matcher && typeof matcher === "object") {
            if (matcher === object) {
                return true;
            }
            var prop;
            // eslint-disable-next-line guard-for-in
            for (prop in matcher) {
                var value = object[prop];
                if (
                    typeof value === "undefined" &&
                    typeof object.getAttribute === "function"
                ) {
                    value = object.getAttribute(prop);
                }
                if (
                    matcher[prop] === null ||
                    typeof matcher[prop] === "undefined"
                ) {
                    if (value !== matcher[prop]) {
                        return false;
                    }
                } else if (
                    typeof value === "undefined" ||
                    !match(value, matcher[prop])
                ) {
                    return false;
                }
            }
            return true;
        }

        throw new Error(
            "Matcher was not a string, a number, a " +
                "function, a boolean or an object"
        );
    }

    var match_1 = match;

    var samsam = {
        isArguments: isArguments_1,
        isElement: isElement_1,
        isNegZero: isNegZero_1,
        identical: identical_1,
        deepEqual: deepEqual,
        match: match_1
    };
    var samsam_1 = samsam.isArguments;
    var samsam_2 = samsam.isElement;
    var samsam_3 = samsam.isNegZero;
    var samsam_4 = samsam.identical;
    var samsam_5 = samsam.deepEqual;
    var samsam_6 = samsam.match;

    exports.default = samsam;
    exports.isArguments = samsam_1;
    exports.isElement = samsam_2;
    exports.isNegZero = samsam_3;
    exports.identical = samsam_4;
    exports.deepEqual = samsam_5;
    exports.match = samsam_6;

    Object.defineProperty(exports, '__esModule', { value: true });

})));
