(function() {
  var ACCESS_GRANTED_STATUS = 'storage_access_granted';
  var ACCESS_DENIED_STATUS = 'storage_access_denied';

  function StorageAccessHelper(redirectData) {
    this.redirectData = redirectData;
  }

  StorageAccessHelper.prototype.setNormalizedLink = function(storageAccessStatus) {
    return storageAccessStatus === ACCESS_GRANTED_STATUS ? this.redirectData.hasStorageAccessUrl : this.redirectData.doesNotHaveStorageAccessUrl;
  }

  StorageAccessHelper.prototype.redirectToAppTLD = function(storageAccessStatus) {
    var normalizedLink = document.createElement('a');

    normalizedLink.href = this.setNormalizedLink(storageAccessStatus);

    data = JSON.stringify({
      message: 'Shopify.API.remoteRedirect',
      data: {
        location: normalizedLink.href,
      }
    });
    window.parent.postMessage(data, this.redirectData.myshopifyUrl);
  }

  StorageAccessHelper.prototype.redirectToAppsIndex = function() {
    window.parent.location.href = this.redirectData.myshopifyUrl + '/admin/apps';
  }

  StorageAccessHelper.prototype.redirectToAppHome = function() {
    window.location.href = this.redirectData.appHomeUrl;
  }

  StorageAccessHelper.prototype.sameSiteNoneIncompatible = function(ua) {
    return ua.includes("iPhone OS 12_") || ua.includes("iPad; CPU OS 12_") || //iOS 12
    (ua.includes("UCBrowser/")
        ? this.isOlderUcBrowser(ua) //UC Browser < 12.13.2
        : (ua.includes("Chrome/5") || ua.includes("Chrome/6"))) ||
    ua.includes("Chromium/5") || ua.includes("Chromium/6") ||
    (ua.includes(" OS X 10_14_") &&
        ((ua.includes("Version/") && ua.includes("Safari")) || //Safari on MacOS 10.14
        ua.endsWith("(KHTML, like Gecko)"))); //Web view on MacOS 10.14
  }

  StorageAccessHelper.prototype.isOlderUcBrowser = function(ua) {
    var match = ua.match(/UCBrowser\/(\d+)\.(\d+)\.(\d+)\./);
    if (!match) return false;
    var major = parseInt(match[1]);
    var minor = parseInt(match[2]);
    var build = parseInt(match[3]);
    if (major != 12) return major < 12;
    if (minor != 13) return minor < 13;
    return build < 2;
  }

  StorageAccessHelper.prototype.setCookie = function(value) {
    if(!this.sameSiteNoneIncompatible(navigator.userAgent)) {
      value += '; secure; SameSite=None'
    }
    document.cookie = value;
  }

  StorageAccessHelper.prototype.grantedStorageAccess = function() {
    try {
      sessionStorage.setItem('shopify.granted_storage_access', true);
      this.setCookie('shopify.granted_storage_access=true');
      if (!document.cookie) {
        throw 'Cannot set third-party cookie.'
      }
      this.redirectToAppHome();
    } catch (error) {
      console.warn('Third party cookies may be blocked.', error);
      this.redirectToAppTLD(ACCESS_DENIED_STATUS);
    }
  }

  StorageAccessHelper.prototype.handleRequestStorageAccess = function() {
    return document.requestStorageAccess().then(this.grantedStorageAccess.bind(this), this.redirectToAppsIndex.bind(this, ACCESS_DENIED_STATUS));
  }

  StorageAccessHelper.prototype.setupRequestStorageAccess = function() {
    var requestContent = document.getElementById('RequestStorageAccess');
    var requestButton = document.getElementById('TriggerAllowCookiesPrompt');

    requestButton.addEventListener('click', this.handleRequestStorageAccess.bind(this));
    requestContent.style.display = 'block';
  }

  StorageAccessHelper.prototype.handleHasStorageAccess = function() {
    if (sessionStorage.getItem('shopify.granted_storage_access')) {
      // If app was classified by ITP and used Storage Access API to acquire access
      this.redirectToAppHome();
    } else {
      // If app has not been classified by ITP and still has storage access
      this.redirectToAppTLD(ACCESS_GRANTED_STATUS);
    }
  }

  StorageAccessHelper.prototype.handleGetStorageAccess = function() {
    if (sessionStorage.getItem('shopify.top_level_interaction')) {
      // If merchant has been redirected to interact with TLD (requirement for prompting request to gain storage access)
      this.setupRequestStorageAccess();
    } else {
      // If merchant has not been redirected to interact with TLD (requirement for prompting request to gain storage access)
      this.redirectToAppTLD(ACCESS_DENIED_STATUS);
    }
  }

  StorageAccessHelper.prototype.manageStorageAccess = function() {
    return document.hasStorageAccess().then(function(hasAccess) {
      if (hasAccess) {
        this.handleHasStorageAccess();
      } else {
        this.handleGetStorageAccess();
      }
    }.bind(this));
  }

  StorageAccessHelper.prototype.execute = function() {
    if (ITPHelper.prototype.canPartitionCookies()) {
      this.setUpCookiePartitioning();
      return;
    }

    if (ITPHelper.prototype.userAgentIsAffected()) {
      this.manageStorageAccess();
    } else {
      this.grantedStorageAccess();
    }
  }

  /* ITP 2.0 solution: handles cookie partitioning */
  StorageAccessHelper.prototype.setUpHelper = function() {
    return new ITPHelper({redirectUrl: window.shopOrigin + "/admin/apps/" + window.apiKey + window.returnTo});
  }

  StorageAccessHelper.prototype.setCookieAndRedirect = function() {
    this.setCookie('shopify.cookies_persist=true');
    var helper = this.setUpHelper();
    helper.redirect();
  }

  StorageAccessHelper.prototype.setUpCookiePartitioning = function() {
    var itpContent = document.getElementById('CookiePartitionPrompt');
    itpContent.style.display = 'block';

    var button = document.getElementById('AcceptCookies');
    button.addEventListener('click', this.setCookieAndRedirect.bind(this));
  }

  this.StorageAccessHelper = StorageAccessHelper;
})(window);
