(function() {
  function setCookieAndRedirect() {
    document.cookie = "shopify.cookies_persist=true";
    var helper = new ITPHelper({redirectUrl: window.shopOrigin + "/admin/apps/" + window.apiKey});
    helper.redirect();
  }

  document.addEventListener("DOMContentLoaded", function() {
    var storageAccessHelper = new StorageAccessHelper();
    storageAccessHelper.execute();
  });
})();

