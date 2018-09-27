var ACCESS_GRANTED_STATUS = 'access granted';
var ACCESS_DENIED_STATUS = 'access denied';

function StorageAccessHelper(redirectInfo) {
  this.redirectInfo = redirectInfo;
}

StorageAccessHelper.prototype.setNormalizedLink = function(storageAccessStatus) {
  return storageAccessStatus === ACCESS_GRANTED_STATUS ? this.redirectInfo.hasStorageAccessUrl : this.redirectInfo.doesNotHaveStorageAccessUrl;
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
  window.parent.postMessage(data, this.redirectInfo.myshopifyUrl);
  sessionStorage.setItem('shopify.has_redirected', 'true');
}

StorageAccessHelper.prototype.redirectToAppHome = function() {
  sessionStorage.setItem('shopify.granted_storage_access', 'true');
  window.location.href = this.redirectInfo.hasStorageAccessUrl;
}

StorageAccessHelper.prototype.handleRequestStorageAccess = function() {
  return document.requestStorageAccess().then(this.redirectToAppHome.bind(this), this.redirectToAppTLD.bind(this, ACCESS_DENIED_STATUS));
}

StorageAccessHelper.prototype.setupRequestStorageAccess = function() {
  const requestContent = document.querySelector('#RequestStorageAccess');
  const requestButton = document.querySelector('#TriggerAllowCookiesPrompt');

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
  if (sessionStorage.getItem('shopify.has_redirected')) {
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
  if (ITPHelper.prototype.userAgentIsAffected()) {
    this.manageStorageAccess();
  } else {
    this.redirectToAppHome();
  }
}
