(function() {
  function setCookieAndRedirect() {
    document.cookie = "shopify.cookies_persist=true";
    ITPHelper.prototype.redirectToEmbedded();
  }

  document.addEventListener("DOMContentLoaded", function() {
    if (ITPHelper.prototype.userAgentIsAffected() && ITPHelper.prototype.canPartitionCookies()) {
      var itpContent = document.querySelector('#CookiePartitionPrompt');
      itpContent.style.display = 'block';

      var button = document.querySelector('#AcceptCookies');
      button.addEventListener('click', setCookieAndRedirect);
    } else {
      setCookieAndRedirect();
    }
  });
})();

