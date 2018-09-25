"use strict";

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } } function _next(value) { step("next", value); } function _throw(err) { step("throw", err); } _next(); }); }; }

const babel = require("@babel/core");

const promisify = require("util.promisify");

const LoaderError = require("./Error");

const transform = promisify(babel.transform);

module.exports =
/*#__PURE__*/
function () {
  var _ref = _asyncToGenerator(function* (source, options) {
    let result;

    try {
      result = yield transform(source, injectCaller(options));
    } catch (err) {
      throw err.message && err.codeFrame ? new LoaderError(err) : err;
    }

    if (!result) return null; // We don't return the full result here because some entries are not
    // really serializable. For a full list of properties see here:
    // https://github.com/babel/babel/blob/master/packages/babel-core/src/transformation/index.js
    // For discussion on this topic see here:
    // https://github.com/babel/babel-loader/pull/629

    const {
      ast,
      code,
      map,
      metadata,
      sourceType
    } = result;

    if (map && (!map.sourcesContent || !map.sourcesContent.length)) {
      map.sourcesContent = [source];
    }

    return {
      ast,
      code,
      map,
      metadata,
      sourceType
    };
  });

  return function (_x, _x2) {
    return _ref.apply(this, arguments);
  };
}();

module.exports.version = babel.version;

function injectCaller(opts) {
  if (!supportsCallerOption()) return opts;
  return Object.assign({}, opts, {
    caller: Object.assign({
      name: "babel-loader",
      // Webpack >= 2 supports ESM and dynamic import.
      supportsStaticESM: true,
      supportsDynamicImport: true
    }, opts.caller)
  });
} // TODO: We can remove this eventually, I'm just adding it so that people have
// a little time to migrate to the newer RCs of @babel/core without getting
// hard-to-diagnose errors about unknown 'caller' options.


let supportsCallerOptionFlag = undefined;

function supportsCallerOption() {
  if (supportsCallerOptionFlag === undefined) {
    try {
      // Rather than try to match the Babel version, we just see if it throws
      // when passed a 'caller' flag, and use that to decide if it is supported.
      babel.loadPartialConfig({
        caller: undefined,
        babelrc: false,
        configFile: false
      });
      supportsCallerOptionFlag = true;
    } catch (err) {
      supportsCallerOptionFlag = false;
    }
  }

  return supportsCallerOptionFlag;
}