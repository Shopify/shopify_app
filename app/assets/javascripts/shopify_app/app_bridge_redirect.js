//= require ./app_bridge_2.0.10.js

(function(window) {
  function appBridgeRedirect(url) {
    var AppBridge = window['app-bridge'];
    var createApp = AppBridge.default;
    var Redirect = AppBridge.actions.Redirect;
    var shopifyData = document.body.dataset;

    var app = createApp({
      apiKey: shopifyData.apiKey,
      shopOrigin: shopifyData.shopOrigin,
      forceRedirect: false,
    });

    var normalizedLink = document.createElement('a');
    normalizedLink.href = url;

    Redirect.create(app).dispatch(Redirect.Action.REMOTE, normalizedLink.href);
  }

  window.appBridgeRedirect = appBridgeRedirect;
})(window);
