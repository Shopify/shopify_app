(function() {
  function ITPHelper() {
    this.itpContent = document.querySelector('#CookiePartitionPrompt');
    this.itpAction = document.querySelector('#AcceptCookies');
  }

  ITPHelper.prototype.setCookieAndRedirect = function() {
    document.cookie = "shopify.cookies_persist=true";
    window.location.href = window.shopOrigin + "/admin/apps/" + window.apiKey;
  }

  ITPHelper.prototype.shouldDisplayPrompt = function() {
    if (navigator.userAgent.indexOf('com.jadedpixel.pos') !== -1) {
      return false;
    }

    if (navigator.userAgent.indexOf('Shopify Mobile/iOS') !== -1) {
      return false;
    }

    return Boolean(document.hasStorageAccess);
  }

  ITPHelper.prototype.execute = function() {
    if (this.shouldDisplayPrompt()) {
      this.itpContent.style.display = 'block';
      this.itpAction.addEventListener('click', this.setCookieAndRedirect.bind(this));
    } else {
      this.setCookieAndRedirect();
    }
  }

  document.addEventListener("DOMContentLoaded", function() {
    var itpHelper = new ITPHelper();
    if (!itpHelper.itpContent) {
      return;
    }
    itpHelper.execute();
  });
})();
