//= require ./app_bridge_redirect.js

(function () {
  function redirect() {
    var redirectTargetElement = document.getElementById("redirection-target");

    if (!redirectTargetElement) {
      return;
    }

    var targetInfo = JSON.parse(redirectTargetElement.dataset.target);

    var appBridgeUtils = window['app-bridge'].utilities;

    if (appBridgeUtils.isShopifyEmbedded()) {
      window.appBridgeRedirect(targetInfo.url);
    } else {
      window.top.location.href = targetInfo.url;
    }
  }

  document.addEventListener("DOMContentLoaded", redirect);

  // In the turbolinks context, neither DOMContentLoaded nor turbolinks:load
  // consistently fires. This ensures that we at least attempt to fire in the
  // turbolinks situation as well.
  redirect();
})();
