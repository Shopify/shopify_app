//= require ./app_bridge_3.1.1.js

(function(window) {
  function appBridgeRedirect(url) {
    var AppBridge = window['app-bridge'];
    var createApp = AppBridge.default;
    var Redirect = AppBridge.actions.Redirect;
    var shopifyData = document.body.dataset;

    var app = createApp({
      apiKey: shopifyData.apiKey,
      host: shopifyData.host,
    });

    var normalizedLink = document.createElement('a');
    normalizedLink.href = url;

    Redirect.create(app).dispatch(Redirect.Action.REMOTE, normalizedLink.href);
  }

  window.appBridgeRedirect = appBridgeRedirect;
})(window);