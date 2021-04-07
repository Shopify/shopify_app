//= require ./app_bridge_redirect_1.30.0.js

(function() {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");
    var bodyElement = document.getElementsByTagName('body')[0];

    if (!redirectTargetElement || !bodyElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target)

    if (window.top == window.self) {
      // If the current window is the 'parent', change the URL by setting location.href
      window.top.location.href = targetInfo.url;
    } else {
      // If the current window is the 'child' or embedded, change the parent's URL with App Bridge redirect
      // This case happens when the app is installed but the app does not know that because there's no shop entry
      normalizedLink = document.createElement('a');
      normalizedLink.href = targetInfo.url;

      var AppBridge = window['app-bridge'];
      var actions = window['app-bridge'].actions;
      var apiKey = bodyElement.dataset.apiKey;
      var urlParams = new URLSearchParams(window.location.search);

      var app = AppBridge.createApp({
        apiKey: apiKey,
        shopOrigin: urlParams.get('shop'),
      });

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
