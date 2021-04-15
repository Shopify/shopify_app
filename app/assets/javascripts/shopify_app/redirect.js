//= require ./app_bridge_1.30.0.js

(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    console.log('HELP');

    if (!redirectTargetElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.url;
    } else {
      // If the current window is the 'child' or embedded, change the parent's URL with App Bridge redirect
      // This case can happen when an app updates its access scopes, or when the shop thinks the app is installed, but
      // the app does not have shop entry
      normalizedLink = document.createElement('a');
      normalizedLink.href = targetInfo.url;

      var AppBridge = window['app-bridge'];
      var actions = window['app-bridge'].actions;
      var urlParams = new URLSearchParams(window.location.search);

      var app = AppBridge.createApp({
        apiKey: window.apiKey,
        shopOrigin: window.shopOrigin,
        foreceRedirect: false,
      });

      console.log('app', app);
      console.log('redirect', redirect);

      var redirect = actions.Redirect.create(app);
      redirect.dispatch(actions.Redirect.Action.REMOTE, normalizedLink.href);
    }
  }

  document.addEventListener("DOMContentLoaded", redirect);

  // In the turbolinks context, neither DOMContentLoaded nor turbolinks:load
  // consistently fires. This ensures that we at least attempt to fire in the
  // turbolinks situation as well.
  redirect();
})();
