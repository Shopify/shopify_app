document.addEventListener('DOMContentLoaded', () => {
  var data = document.getElementById('shopify-app-init').dataset;
  var AppBridge = window['app-bridge'];
  var createApp = AppBridge.default;
  var forceRedirect = (typeof data.forceRedirect === 'undefined' || data.forceRedirect === 'true');
  window.app = createApp({
    apiKey: data.apiKey,
    shopOrigin: data.shopOrigin,
    forceRedirect,
  });

  var actions = AppBridge.actions;
  var TitleBar = actions.TitleBar;
  TitleBar.create(app, {
    title: data.page,
  });
});
