(function(window) {
  function appBridgeRedirect(url) {
    var normalizedLink = document.createElement('a');
    normalizedLink.href = url;

    open(normalizedLink.href, '_top');
  }

  window.appBridgeRedirect = appBridgeRedirect;
})(window);
