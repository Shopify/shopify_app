var ACCESS_GRANTED_STATUS = 'access granted';
var ACCESS_DENIED_STATUS = 'access denied';

function StorageAccessHelper(redirectInfo) {
  this.redirectInfo = redirectInfo;
}

StorageAccessHelper.prototype.redirectToAppTLD = function(storageAccessStatus) {
  // needed for first redirect, if merchant has not interacted with TLD
  var normalizedLink = document.createElement('a');

  normalizedLink.href = storageAccessStatus === ACCESS_GRANTED_STATUS ? this.redirectInfo.hasStorageAccessUrl : this.redirectInfo.doesNotHaveStorageAccessUrl;

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
  window.location.href = `${this.redirectInfo.home}`;
}

StorageAccessHelper.prototype.renderRequestStorageAccess = function() {
  const requestContent = document.querySelector('#RequestStorageAccess');
  const requestButton = document.querySelector('#TriggerAllowCookiesPrompt');

  requestButton.addEventListener('click', () => {
    // If request for storage access is rejected, change the parent's URL with postMessage.
    // If storage access is granted, redirect child to app home page
    document.requestStorageAccess().then(this.redirectToAppHome.bind(this), this.redirectToAppTLD.bind(this, ACCESS_DENIED_STATUS));
  });
  requestContent.style.display = 'block';
}

StorageAccessHelper.prototype.execute = function() {
  document.hasStorageAccess().then((hasAccess) => {
    if (hasAccess) {
      if (sessionStorage.getItem('shopify.granted_storage_access')) {
        // If app was classified by ITP and used Storage Access API to acquire access
        this.redirectToAppHome();
      } else {
        // If app has not been classified by ITP and still has storage access
        this.redirectToAppTLD(ACCESS_GRANTED_STATUS);
      }
    } else {
      if (sessionStorage.getItem('shopify.has_redirected')) {
        // If merchant has been redirected to interact with TLD (requirement for prompting request to gain storage access)
        this.renderRequestStorageAccess();
      } else {
        // If merchant has not been redirected to interact with TLD (requirement for prompting request to gain storage access)
        this.redirectToAppTLD(ACCESS_DENIED_STATUS);
      }
    }
  });
}

function handleStorageAccess(redirectInfo) {
  const storageAccessHelper = new StorageAccessHelper(redirectInfo);

  document.hasStorageAccess().then((hasAccess) => {
    if (hasAccess) {
      if (sessionStorage.getItem('shopify.granted_storage_access')) {
        // If app was classified by ITP and used Storage Access API to acquire access
        storageAccessHelper.redirectToAppHome();
      } else {
        // If app has not been classified by ITP and still has storage access
        storageAccessHelper.redirectToAppTLD(ACCESS_GRANTED_STATUS);
      }
    } else {
      if (sessionStorage.getItem('shopify.has_redirected')) {
        // If merchant has been redirected to interact with TLD (requirement for prompting request to gain storage access)
        storageAccessHelper.renderRequestStorageAccess();
      } else {
        // If merchant has not been redirected to interact with TLD (requirement for prompting request to gain storage access)
        storageAccessHelper.redirectToAppTLD(ACCESS_DENIED_STATUS);
      }
    }
  });
}