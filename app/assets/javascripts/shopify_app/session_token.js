//= require ./app_bridge_session_token.js

(function() {
  function fetchToken() {
    appBridgeFetchSessionToken();
  }

  document.addEventListener("DOMContentLoaded", fetchToken);

  // In the turbolinks context, neither DOMContentLoaded nor turbolinks:load
  // consistently fires. This ensures that we at least attempt to fire in the
  // turbolinks situation as well.
  fetchToken();
  console.log("Called FETCH TOKEN");
})();
