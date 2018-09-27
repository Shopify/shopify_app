(function(redirect) {
  function setCookiesPersist() {
    document.cookie = "shopify.cookies_persist=true";
  }

  function setUpPartitionCookies() {
    var PartitionCookies = new ITPHelper({
      content: '#CookiePartitionPrompt',
      action: '#AcceptCookies',
    });

    if (!PartitionCookies.itpContent) {
      return;
    }

    PartitionCookies.redirectToEmbedded = function() {
      setCookiesPersist();
      redirect();
    }

    if (PartitionCookies.userAgentIsAffected()) {
      PartitionCookies.setUpContent.call(PartitionCookies);
    } else {
      PartitionCookies.redirectToEmbedded();
    }
  }

  document.addEventListener("DOMContentLoaded", setUpPartitionCookies);
})(ITPHelper.prototype.redirectToEmbedded);

