(function() {
  function setCookiesPersist() {
    document.cookie = "shopify.cookies_persist=true";
  }

  function setUpPartitionCookies() {
    var PartitionCookies = new ITPHelper({
      content: '#CookiePartitionPrompt',
      action: '#AcceptCookies',
    });

    if (PartitionCookies.userAgentIsAffected() && navigator.userAgent.indexOf('Version/12.1 Safari') === -1) {
      PartitionCookies.setUpContent(setCookiesPersist);
    } else {
      PartitionCookies.redirectToEmbedded();
    }
  }

  document.addEventListener("DOMContentLoaded", setUpPartitionCookies);
})();

