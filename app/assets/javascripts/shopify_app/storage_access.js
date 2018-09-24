function redirectViaPostMessage(opts) {
  // needed for first redirect, if merchant has not interacted with TLD
  var normalizedLink = document.createElement('a');

  normalizedLink.href = opts.hasStorageAccess ? opts.redirectInfo.hasStorageAccessUrl : opts.redirectInfo.doesNotHaveStorageAccessUrl;

  data = JSON.stringify({
    message: 'Shopify.API.remoteRedirect',
    data: {
      location: normalizedLink.href,
    }
  });
  window.parent.postMessage(data, opts.redirectInfo.myshopifyUrl);
  sessionStorage.setItem('shopify.has_redirected', 'true');
}

function redirectToAppHome(homeURL) {
  sessionStorage.setItem('shopify.granted_storage_access', 'true');
  window.location.href = `${homeURL}`;
}

function handleStorageAccess(redirectInfo) {
  document.hasStorageAccess().then((hasAccess) => {
    if (hasAccess) {
      if (sessionStorage.getItem('shopify.granted_storage_access')) {
        // shopify.granted_storage_access is defined after we successfully request storage access when app is classified by ITP
        redirectToAppHome(redirectInfo.home);
      } else {
        // Re-direct to TLD if app has not been classified by ITP
        redirectViaPostMessage({hasStorageAccess: true, redirectInfo: redirectInfo});
      }
    } else if (!sessionStorage.getItem('shopify.has_redirected')) {
      redirectViaPostMessage({hasStorageAccess: false, redirectInfo: redirectInfo});
    } else {
      // window.location.href = redirectInfo.requestStorageAccess;
      const requestContent = document.querySelector('#RequestStorageAccess');
      const requestButton = document.querySelector('#TriggerAllowCookiesPrompt');
      requestButton.addEventListener('click', () => {
        // If request for storage access is rejected, change the parent's URL with postMessage.
        // If storage access is granted, redirect child to app home page
        document.requestStorageAccess().then(() => {redirectToAppHome(redirectInfo.home)}, () => {redirectViaPostMessage({hasStorageAccess: false, redirectInfo: redirectInfo})});
      });
      requestContent.style.display = 'block';
    }
  });
}