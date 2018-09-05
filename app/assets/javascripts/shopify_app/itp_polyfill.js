(function() {
  function setCookieAndRedirect() {
    document.cookie = "shopify.cookies_persist=true";
    window.location.href = window.shopOrigin + "/admin/apps/" + window.apiKey;
  }

  function shouldDisplayPrompt() {
    if (navigator.userAgent.indexOf('com.jadedpixel.pos') !== -1) {
      return false;
    }

    if (navigator.userAgent.indexOf('Shopify Mobile/iOS') !== -1) {
      return false;
    }

    return Boolean(document.hasStorageAccess);
  }

  document.addEventListener("DOMContentLoaded", function() {
    if (shouldDisplayPrompt()) {
      var itpContent = document.querySelector('#CookiePartitionPrompt');
      itpContent.style.display = 'block';

      var button = document.querySelector('#AcceptCookies');
      button.addEventListener('click', setCookieAndRedirect);
    } else {
      setCookieAndRedirect();
    }
  });
})();
