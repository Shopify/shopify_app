(function(window) {
  window.should = null; // Workaround for "RangeError: Maximum call stack size exceeded." in PhantomJS
  window.should = window.chai.should();
  window.expect = window.chai.expect;
  window.assert = window.chai.assert;
})(window);