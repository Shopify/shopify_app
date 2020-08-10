(function(window) {
  function appBridgeRedirect(url) {
    var AppBridge = window['app-bridge'];
    var createApp = AppBridge.default;
    var Redirect = AppBridge.actions.Redirect;
    var app = createApp({
      apiKey: window.apiKey,
      shopOrigin: window.shopOrigin.replace(/^https:\/\//, ''),
    });
  
    var normalizedLink = document.createElement('a');
    normalizedLink.href = url;

    console.log('aaaaaaaaaa appBridgeRedirect', window.top === window.self);
  
    Redirect.create(app).dispatch(Redirect.Action.REMOTE, normalizedLink.href);
  }

  window.appBridgeRedirect = appBridgeRedirect;
})(window);
